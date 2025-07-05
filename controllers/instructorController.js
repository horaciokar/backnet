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
      
      res.render('instructor/dashboard', {
        title: 'Panel de Instructor',
        user,
        courses,
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
      
      let whereClause = {};
      if (courseId) {
        whereClause.course_id = courseId;
      }
      
      const enrollments = await Enrollment.findAll({
        where: whereClause,
        include: [
          {
            model: User,
            as: 'student',
            attributes: ['id', 'first_name', 'last_name', 'email']
          },
          {
            model: Course,
            as: 'course',
            where: { created_by: user.id }
          }
        ],
        order: [['enrolled_at', 'DESC']]
      });
      
      const courses = await Course.findAll({
        where: { created_by: user.id, is_active: true },
        order: [['title', 'ASC']]
      });
      
      res.render('instructor/students', {
        title: 'Mis Estudiantes',
        user,
        enrollments,
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
          include: [{
            model: Exam,
            as: 'exams'
          }]
        }]
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
  
  // Crear examen
  static async createExam(req, res) {
    try {
      const user = req.user;
      const { unitId } = req.params;
      
      const unit = await CourseUnit.findOne({
        where: { id: unitId },
        include: [{
          model: Course,
          as: 'course',
          where: { created_by: user.id }
        }]
      });
      
      if (!unit) {
        return res.status(404).render('error', {
          title: 'Unidad no encontrada',
          error: 'No tienes permisos para crear exámenes en esta unidad',
          code: 404
        });
      }
      
      res.render('instructor/create-exam', {
        title: 'Crear Examen',
        user,
        unit
      });
      
    } catch (error) {
      console.error('Error al crear examen:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al crear examen',
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
        order: [['created_at', 'DESC']]
      });
      
      res.render('instructor/reports', {
        title: 'Reportes',
        user,
        courses,
        enrollments,
        examAttempts
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
