const { validationResult } = require('express-validator');
const { Op } = require('sequelize');
const Course = require('../models/Course');
const CourseUnit = require('../models/CourseUnit');
const { Enrollment, EnrollmentCode } = require('../models/Enrollment');
const User = require('../models/User');

class CourseController {
  
  // Listar cursos disponibles
  static async index(req, res) {
    try {
      const { category, search } = req.query;
      const user = req.user;
      
      let whereClause = { is_active: true };
      
      if (category && ['networks', 'security', 'both'].includes(category)) {
        whereClause.category = category;
      }
      
      if (search) {
        whereClause[Op.or] = [
          { title: { [Op.like]: `%${search}%` } },
          { description: { [Op.like]: `%${search}%` } }
        ];
      }
      
      const courses = await Course.findAll({
        where: whereClause,
        order: [['created_at', 'DESC']]
      });
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id },
        attributes: ['course_id', 'progress']
      });
      
      const enrollmentMap = enrollments.reduce((map, enrollment) => {
        map[enrollment.course_id] = enrollment.progress;
        return map;
      }, {});
      
      res.render('courses/index', {
        title: 'Cursos Disponibles',
        courses,
        enrollmentMap,
        category: category || '',
        search: search || '',
        user
      });
      
    } catch (error) {
      console.error('Error al listar cursos:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar los cursos',
        code: 500
      });
    }
  }
  
  // Ver detalles de un curso
  static async show(req, res) {
    try {
      const courseId = req.params.id;
      const user = req.user;
      
      const course = await Course.findByPk(courseId);
      
      if (!course || !course.is_active) {
        return res.status(404).render('error', {
          title: 'Curso no encontrado',
          error: 'El curso solicitado no existe o no está disponible',
          code: 404
        });
      }
      
      // Obtener unidades del curso
      const units = await CourseUnit.findAll({
        where: { course_id: courseId, is_active: true },
        order: [['order_number', 'ASC']]
      });
      
      // Verificar si el usuario está matriculado
      const enrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      // Obtener estadísticas del curso
      const enrollmentCount = await Enrollment.count({
        where: { course_id: courseId }
      });
      
      const unitsCount = units.length;
      
      // Obtener creador del curso
      const creator = await User.findByPk(course.created_by);
      
      res.render('courses/show', {
        title: course.title,
        course: {
          ...course.toJSON(),
          creator,
          units
        },
        enrollment,
        enrollmentCount,
        unitsCount, // ← Esta variable faltaba
        isEnrolled: !!enrollment,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar curso:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el curso',
        code: 500
      });
    }
  }
  
  // Matricularse en un curso
  static async enroll(req, res) {
    try {
      const courseId = req.params.id;
      const user = req.user;
      
      console.log(`Usuario ${user.id} intenta matricularse en curso ${courseId}`);
      
      // Verificar si ya está matriculado
      const existingEnrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      if (existingEnrollment) {
        req.session.error = 'Ya estás matriculado en este curso';
        return res.redirect(`/courses/${courseId}`);
      }
      
      // Verificar que el curso existe
      const course = await Course.findByPk(courseId);
      if (!course || !course.is_active) {
        return res.status(404).render('error', {
          title: 'Curso no encontrado',
          error: 'El curso solicitado no existe',
          code: 404
        });
      }
      
      // Crear matrícula
      await Enrollment.create({
        user_id: user.id,
        course_id: courseId
      });
      
      console.log(`Usuario ${user.id} matriculado exitosamente en curso ${courseId}`);
      
      req.session.message = '¡Te has matriculado exitosamente en el curso!';
      res.redirect(`/courses/${courseId}`);
      
    } catch (error) {
      console.error('Error al matricularse:', error);
      req.session.error = 'Error al matricularse en el curso';
      res.redirect(`/courses/${req.params.id}`);
    }
  }
  
  // Matricularse con código
  static async enrollWithCode(req, res) {
    try {
      console.log('Procesando matrícula con código...');
      console.log('Body:', req.body);
      
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        console.log('Errores de validación:', errors.array());
        req.session.error = errors.array()[0].msg;
        return res.redirect('/courses');
      }
      
      const { enrollment_code } = req.body;
      const user = req.user;
      
      console.log(`Buscando código: ${enrollment_code}`);
      
      // Buscar código
      const code = await EnrollmentCode.findOne({
        where: { 
          code: enrollment_code.toUpperCase(),
          is_active: true
        }
      });
      
      if (!code) {
        console.log('Código no encontrado');
        req.session.error = 'Código de matrícula inválido';
        return res.redirect('/courses');
      }
      
      console.log('Código encontrado:', code.toJSON());
      
      // Verificar si el código puede ser usado
      if (code.used_count >= code.max_uses) {
        req.session.error = 'Código de matrícula agotado';
        return res.redirect('/courses');
      }
      
      if (code.expires_at && new Date() > code.expires_at) {
        req.session.error = 'Código de matrícula expirado';
        return res.redirect('/courses');
      }
      
      // Verificar si ya está matriculado
      const existingEnrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: code.course_id }
      });
      
      if (existingEnrollment) {
        req.session.error = 'Ya estás matriculado en este curso';
        return res.redirect(`/courses/${code.course_id}`);
      }
      
      // Usar código
      await code.increment('used_count');
      
      // Crear matrícula
      await Enrollment.create({
        user_id: user.id,
        course_id: code.course_id
      });
      
      console.log(`Usuario ${user.id} matriculado con código en curso ${code.course_id}`);
      
      req.session.message = '¡Te has matriculado exitosamente con el código!';
      res.redirect(`/courses/${code.course_id}`);
      
    } catch (error) {
      console.error('Error al matricularse con código:', error);
      req.session.error = 'Error al procesar el código de matrícula';
      res.redirect('/courses');
    }
  }
  
  // Mis cursos
  static async myCourses(req, res) {
    try {
      const user = req.user;
      
      const enrollments = await Enrollment.findAll({
        where: { user_id: user.id, is_active: true },
        order: [['enrolled_at', 'DESC']]
      });
      
      // Obtener cursos para cada matrícula
      const enrollmentsWithCourses = [];
      for (const enrollment of enrollments) {
        const course = await Course.findByPk(enrollment.course_id);
        if (course) {
          const creator = await User.findByPk(course.created_by);
          enrollmentsWithCourses.push({
            ...enrollment.toJSON(),
            course: {
              ...course.toJSON(),
              creator
            }
          });
        }
      }
      
      res.render('courses/my-courses', {
        title: 'Mis Cursos',
        enrollments: enrollmentsWithCourses,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar mis cursos:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar tus cursos',
        code: 500
      });
    }
  }
  
  // Mostrar unidad específica
  static async showUnit(req, res) {
    try {
      const { courseId, unitId } = req.params;
      const user = req.user;
      
      // Verificar matrícula
      const enrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      if (!enrollment && user.role === 'student') {
        return res.status(403).render('error', {
          title: 'Acceso denegado',
          error: 'Debes estar matriculado en el curso para acceder a este contenido',
          code: 403
        });
      }
      
      const unit = await CourseUnit.findByPk(unitId);
      
      if (!unit || unit.course_id !== parseInt(courseId)) {
        return res.status(404).render('error', {
          title: 'Unidad no encontrada',
          error: 'La unidad solicitada no existe',
          code: 404
        });
      }
      
      // Obtener curso
      const course = await Course.findByPk(courseId);
      
      // Obtener todas las unidades para navegación
      const allUnits = await CourseUnit.findAll({
        where: { course_id: courseId, is_active: true },
        order: [['order_number', 'ASC']]
      });
      
      // Obtener siguiente y anterior
      const currentIndex = allUnits.findIndex(u => u.id === unit.id);
      const nextUnit = allUnits[currentIndex + 1] || null;
      const previousUnit = allUnits[currentIndex - 1] || null;
      
      // Extraer ID de YouTube si es video
      let videoId = null;
      if (unit.content_type === 'video' && unit.video_url) {
        const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
        const match = unit.video_url.match(regex);
        videoId = match ? match[1] : null;
      }
      
      res.render('courses/unit', {
        title: `${course.title} - ${unit.title}`,
        unit: {
          ...unit.toJSON(),
          course
        },
        allUnits,
        nextUnit,
        previousUnit,
        enrollment,
        videoId,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar unidad:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar la unidad',
        code: 500
      });
    }
  }
}

module.exports = CourseController;
