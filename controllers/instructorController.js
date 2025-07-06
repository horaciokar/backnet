const { validationResult } = require('express-validator');
const Course = require('../models/Course');
const CourseUnit = require('../models/CourseUnit');
const { Enrollment } = require('../models/Enrollment');
const { Exam, Question, ExamAttempt } = require('../models/Exam');
const User = require('../models/User');
const { Op } = require('sequelize');

class InstructorController {
  
  // Panel principal
  static async dashboard(req, res) {
    try {
      const user = req.user;
      
      const courses = await Course.findAll({
        where: { created_by: user.id, is_active: true },
        order: [['created_at', 'DESC']]
      });
      
      const courseIds = courses.map(c => c.id);
      
      const totalStudents = await Enrollment.count({
        where: { course_id: { [Op.in]: courseIds }, is_active: true }
      });
      
      const totalExams = await Exam.count({
        include: [{
          model: CourseUnit,
          as: 'unit',
          where: { course_id: { [Op.in]: courseIds } }
        }]
      });
      
      const recentEnrollments = await Enrollment.findAll({
        where: { course_id: { [Op.in]: courseIds } },
        include: [
          { model: User, as: 'student', attributes: ['first_name', 'last_name'] },
          { model: Course, as: 'course', attributes: ['title'] }
        ],
        order: [['enrolled_at', 'DESC']],
        limit: 5
      });
      
      const recentExamAttempts = await ExamAttempt.findAll({
        where: { completed_at: { [Op.not]: null } },
        include: [
          { model: User, as: 'student', attributes: ['first_name', 'last_name'] },
          { 
            model: Exam, 
            as: 'exam',
            include: [{
              model: CourseUnit,
              as: 'unit',
              where: { course_id: { [Op.in]: courseIds } }
            }]
          }
        ],
        order: [['completed_at', 'DESC']],
        limit: 5
      });
      
      res.render('instructor/dashboard', {
        title: 'Panel de Instructor',
        user,
        courses,
        recentEnrollments,
        recentExamAttempts,
        stats: {
          totalCourses: courses.length,
          totalStudents,
          totalExams
        }
      });
      
    } catch (error) {
      console.error('Error en dashboard instructor:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el panel',
        code: 500
      });
    }
  }
  
  // Ver estudiantes
  static async students(req, res) {
    try {
      const user = req.user;
      const { courseId } = req.query;
      
      // Obtener cursos del instructor
      const courses = await Course.findAll({
        where: { created_by: user.id, is_active: true },
        order: [['title', 'ASC']]
      });
      
      const courseIds = courses.map(c => c.id);
      
      let whereClause = {
        course_id: { [Op.in]: courseIds },
        is_active: true
      };
      
      if (courseId && courseIds.includes(parseInt(courseId))) {
        whereClause.course_id = courseId;
      }
      
      const enrollments = await Enrollment.findAll({
        where: whereClause,
        include: [
          {
            model: User,
            as: 'student',
            attributes: ['id', 'first_name', 'last_name', 'email', 'last_login']
          },
          {
            model: Course,
            as: 'course',
            attributes: ['id', 'title']
          }
        ],
        order: [['enrolled_at', 'DESC']]
      });
      
      // Obtener estadísticas de exámenes por estudiante
      const enrollmentsWithStats = [];
      for (const enrollment of enrollments) {
        const examAttempts = await ExamAttempt.findAll({
          where: { user_id: enrollment.user_id },
          include: [{
            model: Exam,
            as: 'exam',
            include: [{
              model: CourseUnit,
              as: 'unit',
              where: { course_id: enrollment.course_id }
            }]
          }]
        });
        
        const completedExams = examAttempts.filter(a => a.completed_at);
        const passedExams = examAttempts.filter(a => a.passed);
        const avgScore = completedExams.length > 0 
          ? Math.round(completedExams.reduce((sum, a) => sum + (a.score || 0), 0) / completedExams.length)
          : 0;
        
        enrollmentsWithStats.push({
          ...enrollment.toJSON(),
          examStats: {
            total: examAttempts.length,
            completed: completedExams.length,
            passed: passedExams.length,
            avgScore
          }
        });
      }
      
      res.render('instructor/students', {
        title: 'Mis Estudiantes',
        user,
        enrollments: enrollmentsWithStats,
        courses,
        selectedCourse: courseId
      });
      
    } catch (error) {
      console.error('Error al mostrar estudiantes:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar estudiantes',
        code: 500
      });
    }
  }
  
  // Gestionar exámenes
  static async exams(req, res) {
    try {
      const user = req.user;
      
      const courses = await Course.findAll({
        where: { created_by: user.id, is_active: true },
        include: [{
          model: CourseUnit,
          as: 'units',
          where: { is_active: true },
          required: false,
          include: [{
            model: Exam,
            as: 'exams',
            required: false
          }]
        }],
        order: [['title', 'ASC'], [{ model: CourseUnit, as: 'units' }, 'order_number', 'ASC']]
      });
      
      res.render('instructor/exams', {
        title: 'Gestión de Exámenes',
        user,
        courses
      });
      
    } catch (error) {
      console.error('Error en gestión de exámenes:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar exámenes',
        code: 500
      });
    }
  }
  
  // Reportes
  static async reports(req, res) {
    try {
      const user = req.user;
      
      const courses = await Course.findAll({
        where: { created_by: user.id, is_active: true }
      });
      
      const courseIds = courses.map(c => c.id);
      
      // Estadísticas generales
      const enrollments = await Enrollment.findAll({
        where: { course_id: { [Op.in]: courseIds }, is_active: true },
        include: [{
          model: Course,
          as: 'course'
        }]
      });
      
      const examAttempts = await ExamAttempt.findAll({
        where: { completed_at: { [Op.not]: null } },
        include: [{
          model: Exam,
          as: 'exam',
          include: [{
            model: CourseUnit,
            as: 'unit',
            where: { course_id: { [Op.in]: courseIds } }
          }]
        }],
        order: [['created_at', 'DESC']]
      });
      
      // Estadísticas por curso
      const courseStats = {};
      for (const course of courses) {
        const courseEnrollments = enrollments.filter(e => e.course_id === course.id);
        const courseExams = examAttempts.filter(a => 
          a.exam.unit.course_id === course.id
        );
        const passedExams = courseExams.filter(a => a.passed);
        
        courseStats[course.id] = {
          enrollments: courseEnrollments.length,
          examAttempts: courseExams.length,
          passedExams: passedExams.length,
          avgScore: courseExams.length > 0 
            ? Math.round(courseExams.reduce((sum, a) => sum + (a.score || 0), 0) / courseExams.length)
            : 0
        };
      }
      
      res.render('instructor/reports', {
        title: 'Reportes',
        user,
        courses,
        enrollments,
        examAttempts,
        courseStats
      });
      
    } catch (error) {
      console.error('Error en reportes:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al generar reportes',
        code: 500
      });
    }
  }
}

module.exports = InstructorController;
