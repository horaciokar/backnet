const { Enrollment } = require('../models/Enrollment');
const Course = require('../models/Course');
const { ExamAttempt } = require('../models/Exam');
const User = require('../models/User');
const { Op } = require('sequelize');

class DashboardController {
  static async index(req, res) {
    try {
      const user = req.user;
      
      switch(user.role) {
        case 'admin':
          return res.redirect('/admin/dashboard');
        case 'instructor':
          return DashboardController.instructorDashboard(req, res);
        case 'student':
          return DashboardController.studentDashboard(req, res);
        default:
          return res.redirect('/auth/login');
      }
    } catch (error) {
      console.error('Error en dashboard:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el dashboard',
        code: 500
      });
    }
  }
  
  static async studentDashboard(req, res) {
    try {
      const user = req.user;
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id, is_active: true },
        include: [{
          model: Course,
          as: 'course',
          where: { is_active: true }
        }],
        order: [['enrolled_at', 'DESC']]
      });
      
      const examAttempts = await ExamAttempt.findAll({
        where: { user_id: user.id },
        order: [['created_at', 'DESC']],
        limit: 5
      });
      
      const totalCourses = enrollments.length;
      const completedCourses = enrollments.filter(e => e.progress >= 100).length;
      const totalExams = examAttempts.length;
      const passedExams = examAttempts.filter(e => e.passed).length;
      
      const avgProgress = enrollments.length > 0 
        ? Math.round(enrollments.reduce((sum, e) => sum + e.progress, 0) / enrollments.length)
        : 0;
      
      res.render('dashboard/student', {
        title: 'Dashboard Estudiante',
        user,
        enrollments,
        examAttempts,
        stats: {
          totalCourses,
          completedCourses,
          totalExams,
          passedExams,
          avgProgress
        }
      });
      
    } catch (error) {
      console.error('Error en dashboard estudiante:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el dashboard',
        code: 500
      });
    }
  }
  
  static async instructorDashboard(req, res) {
    try {
      const user = req.user;
      
      const courses = await Course.findAll({
        where: { 
          created_by: user.id,
          is_active: true 
        },
        order: [['created_at', 'DESC']]
      });
      
      const courseIds = courses.map(c => c.id);
      const totalStudents = await Enrollment.count({
        where: { 
          course_id: { [Op.in]: courseIds },
          is_active: true 
        }
      });
      
      const recentExamAttempts = await ExamAttempt.findAll({
        where: {
          completed_at: { [Op.not]: null },
          created_at: { [Op.gte]: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        },
        order: [['created_at', 'DESC']],
        limit: 10
      });
      
      res.render('dashboard/instructor', {
        title: 'Dashboard Instructor',
        user,
        courses,
        recentExamAttempts,
        stats: {
          totalCourses: courses.length,
          totalStudents,
          recentExams: recentExamAttempts.length
        }
      });
      
    } catch (error) {
      console.error('Error en dashboard instructor:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el dashboard',
        code: 500
      });
    }
  }
  
  static async progressDetail(req, res) {
    try {
      const user = req.user;
      
      if (user.role !== 'student') {
        return res.status(403).render('error', {
          title: 'Acceso denegado',
          error: 'Solo estudiantes pueden ver progreso detallado',
          code: 403
        });
      }
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id, is_active: true },
        include: [{
          model: Course,
          as: 'course'
        }],
        order: [['enrolled_at', 'DESC']]
      });
      
      const examAttempts = await ExamAttempt.findAll({
        where: { user_id: user.id },
        order: [['created_at', 'DESC']]
      });
      
      res.render('dashboard/progress', {
        title: 'Progreso Detallado',
        user,
        enrollments,
        examAttempts
      });
      
    } catch (error) {
      console.error('Error en progreso detallado:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el progreso',
        code: 500
      });
    }
  }
}

module.exports = DashboardController;
