const { validationResult } = require('express-validator');
const User = require('../models/User');
const Course = require('../models/Course');
const { Enrollment, EnrollmentCode } = require('../models/Enrollment');
const { ExamAttempt } = require('../models/Exam');
const { Op } = require('sequelize');

class AdminController {
  static async dashboard(req, res) {
    try {
      const totalUsers = await User.count({ where: { is_active: true } });
      const totalCourses = await Course.count({ where: { is_active: true } });
      const totalEnrollments = await Enrollment.count({ where: { is_active: true } });
      const totalExamAttempts = await ExamAttempt.count();
      
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
      
      res.render('admin/dashboard', {
        title: 'Panel de Administración',
        user: req.user,
        stats: {
          totalUsers,
          totalCourses,
          totalEnrollments,
          totalExamAttempts
        },
        recentUsers,
        recentEnrollments
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
  
  static async users(req, res) {
    try {
      const { search, role, page = 1 } = req.query;
      const limit = 20;
      const offset = (page - 1) * limit;
      
      let whereClause = { is_active: true };
      
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
  
  static async toggleUserStatus(req, res) {
    try {
      const { userId } = req.params;
      const user = await User.findByPk(userId);
      
      if (!user) {
        return res.status(404).json({ success: false, message: 'Usuario no encontrado' });
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
}

module.exports = AdminController;
