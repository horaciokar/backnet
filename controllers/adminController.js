const { validationResult } = require('express-validator');
const User = require('../models/User');
const Course = require('../models/Course');
const CourseUnit = require('../models/CourseUnit');
const { Enrollment, EnrollmentCode } = require('../models/Enrollment');
const { Exam, Question, ExamAttempt } = require('../models/Exam');
const { Op } = require('sequelize');
const bcrypt = require('bcryptjs');

class AdminController {
  
  // Dashboard principal
  static async dashboard(req, res) {
    try {
      // Estadísticas generales
      const totalUsers = await User.count({ where: { is_active: true } });
      const totalCourses = await Course.count({ where: { is_active: true } });
      const totalEnrollments = await Enrollment.count({ where: { is_active: true } });
      const totalExamAttempts = await ExamAttempt.count();
      
      // Usuarios por rol
      const usersByRole = await User.findAll({
        attributes: ['role', [User.sequelize.fn('COUNT', User.sequelize.col('id')), 'count']],
        where: { is_active: true },
        group: ['role'],
        raw: true
      });
      
      // Actividad reciente
      const recentUsers = await User.findAll({
        where: { is_active: true },
        order: [['created_at', 'DESC']],
        limit: 5
      });
      
      const recentEnrollments = await Enrollment.findAll({
        include: [
          { model: User, as: 'student', attributes: ['first_name', 'last_name'] },
          { model: Course, as: 'course', attributes: ['title'] }
        ],
        order: [['enrolled_at', 'DESC']],
        limit: 5
      });
      
      // Exámenes recientes
      const recentExams = await ExamAttempt.findAll({
        where: { completed_at: { [Op.not]: null } },
        include: [
          { model: User, as: 'student', attributes: ['first_name', 'last_name'] }
        ],
        order: [['completed_at', 'DESC']],
        limit: 5
      });
      
      res.render('admin/dashboard', {
        title: 'Panel de Administración',
        user: req.user,
        stats: {
          totalUsers,
          totalCourses,
          totalEnrollments,
          totalExamAttempts
        },
        usersByRole,
        recentUsers,
        recentEnrollments,
        recentExams
      });
      
    } catch (error) {
      console.error('Error en dashboard admin:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el panel',
        code: 500
      });
    }
  }
  
  // Gestión de usuarios
  static async users(req, res) {
    try {
      const { search, role, page = 1 } = req.query;
      const limit = 20;
      const offset = (page - 1) * limit;
      
      let whereClause = {};
      
      if (search) {
        whereClause[Op.or] = [
          { first_name: { [Op.like]: `%${search}%` } },
          { last_name: { [Op.like]: `%${search}%` } },
          { email: { [Op.like]: `%${search}%` } }
        ];
      }
      
      if (role && ['admin', 'instructor', 'student'].includes(role)) {
        whereClause.role = role;
      }
      
      const { count, rows: users } = await User.findAndCountAll({
        where: whereClause,
        order: [['created_at', 'DESC']],
        limit,
        offset
      });
      
      const totalPages = Math.ceil(count / limit);
      
      res.render('admin/users', {
        title: 'Gestión de Usuarios',
        user: req.user,
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1
        },
        filters: { search, role }
      });
      
    } catch (error) {
      console.error('Error en gestión de usuarios:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar usuarios',
        code: 500
      });
    }
  }
  
  // Crear usuario
  static async createUser(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        req.session.error = errors.array()[0].msg;
        return res.redirect('/admin/users');
      }
      
      const { email, password, first_name, last_name, role } = req.body;
      
      // Verificar si el email ya existe
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        req.session.error = 'El email ya está registrado';
        return res.redirect('/admin/users');
      }
      
      await User.create({
        email,
        password,
        first_name,
        last_name,
        role,
        is_active: true
      });
      
      req.session.message = 'Usuario creado exitosamente';
      res.redirect('/admin/users');
      
    } catch (error) {
      console.error('Error al crear usuario:', error);
      req.session.error = 'Error al crear el usuario';
      res.redirect('/admin/users');
    }
  }
  
  // Cambiar estado de usuario
  static async toggleUserStatus(req, res) {
    try {
      const { userId } = req.params;
      const user = await User.findByPk(userId);
      
      if (!user) {
        return res.status(404).json({ success: false, message: 'Usuario no encontrado' });
      }
      
      if (user.id === req.user.id) {
        return res.status(400).json({ success: false, message: 'No puedes desactivar tu propia cuenta' });
      }
      
      await user.update({ is_active: !user.is_active });
      
      res.json({ 
        success: true, 
        message: `Usuario ${user.is_active ? 'activado' : 'desactivado'} exitosamente`,
        is_active: user.is_active
      });
      
    } catch (error) {
      console.error('Error al cambiar estado:', error);
      res.status(500).json({ success: false, message: 'Error del servidor' });
    }
  }
  
  // Gestión de cursos
  static async courses(req, res) {
    try {
      const courses = await Course.findAll({
        include: [{
          model: User,
          as: 'creator',
          attributes: ['first_name', 'last_name']
        }],
        order: [['created_at', 'DESC']]
      });
      
      // Obtener estadísticas por curso
      const courseStats = {};
      for (const course of courses) {
        const enrollmentCount = await Enrollment.count({
          where: { course_id: course.id, is_active: true }
        });
        const unitsCount = await CourseUnit.count({
          where: { course_id: course.id, is_active: true }
        });
        const examsCount = await Exam.count({
          include: [{
            model: CourseUnit,
            as: 'unit',
            where: { course_id: course.id }
          }]
        });
        
        courseStats[course.id] = { 
          enrollmentCount, 
          unitsCount, 
          examsCount 
        };
      }
      
      res.render('admin/courses', {
        title: 'Gestión de Cursos',
        user: req.user,
        courses,
        courseStats
      });
      
    } catch (error) {
      console.error('Error en gestión de cursos:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar cursos',
        code: 500
      });
    }
  }
  
  // Códigos de matrícula
  static async enrollmentCodes(req, res) {
    try {
      const codes = await EnrollmentCode.findAll({
        include: [{
          model: Course,
          as: 'course',
          attributes: ['title']
        }],
        order: [['created_at', 'DESC']]
      });
      
      const courses = await Course.findAll({
        where: { is_active: true },
        order: [['title', 'ASC']]
      });
      
      res.render('admin/enrollment-codes', {
        title: 'Códigos de Matrícula',
        user: req.user,
        codes,
        courses
      });
      
    } catch (error) {
      console.error('Error en códigos de matrícula:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar códigos',
        code: 500
      });
    }
  }
  
  // Crear código de matrícula
  static async createEnrollmentCode(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        req.session.error = errors.array()[0].msg;
        return res.redirect('/admin/enrollment-codes');
      }
      
      const { course_id, code, max_uses, expires_at } = req.body;
      
      // Verificar si el código ya existe
      const existingCode = await EnrollmentCode.findOne({
        where: { code: code.toUpperCase() }
      });
      
      if (existingCode) {
        req.session.error = 'El código ya existe';
        return res.redirect('/admin/enrollment-codes');
      }
      
      await EnrollmentCode.create({
        course_id,
        code: code.toUpperCase(),
        max_uses: parseInt(max_uses),
        expires_at: expires_at ? new Date(expires_at) : null,
        created_by: req.user.id
      });
      
      req.session.message = 'Código de matrícula creado exitosamente';
      res.redirect('/admin/enrollment-codes');
      
    } catch (error) {
      console.error('Error al crear código:', error);
      req.session.error = 'Error al crear el código de matrícula';
      res.redirect('/admin/enrollment-codes');
    }
  }
  
  // Reportes generales
  static async reports(req, res) {
    try {
      const { period = 'month' } = req.query;
      
      let dateFrom;
      switch (period) {
        case 'week':
          dateFrom = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
          break;
        case 'month':
          dateFrom = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
          break;
        case 'year':
          dateFrom = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
          break;
        default:
          dateFrom = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      }
      
      // Estadísticas del período
      const newUsers = await User.count({
        where: {
          created_at: { [Op.gte]: dateFrom },
          is_active: true
        }
      });
      
      const newEnrollments = await Enrollment.count({
        where: {
          enrolled_at: { [Op.gte]: dateFrom },
          is_active: true
        }
      });
      
      const examAttempts = await ExamAttempt.count({
        where: {
          created_at: { [Op.gte]: dateFrom }
        }
      });
      
      const passedExams = await ExamAttempt.count({
        where: {
          created_at: { [Op.gte]: dateFrom },
          passed: true
        }
      });
      
      // Top cursos por matrículas
      const topCourses = await Course.findAll({
        include: [{
          model: Enrollment,
          as: 'enrollments',
          where: { is_active: true },
          required: false
        }],
        order: [[User.sequelize.fn('COUNT', User.sequelize.col('enrollments.id')), 'DESC']],
        group: ['Course.id'],
        limit: 5
      });
      
      res.render('admin/reports', {
        title: 'Reportes del Sistema',
        user: req.user,
        period,
        stats: {
          newUsers,
          newEnrollments,
          examAttempts,
          passedExams
        },
        topCourses
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

module.exports = AdminController;
