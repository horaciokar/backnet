const { validationResult } = require('express-validator');
const { Op } = require('sequelize');
const Course = require('../models/Course');
const CourseUnit = require('../models/CourseUnit');
const { Enrollment, EnrollmentCode } = require('../models/Enrollment');
const { Exam, ExamAttempt } = require('../models/Exam');
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
        include: [{
          model: User,
          as: 'creator',
          attributes: ['first_name', 'last_name']
        }],
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
      
      const course = await Course.findOne({
        where: { id: courseId, is_active: true },
        include: [
          {
            model: User,
            as: 'creator',
            attributes: ['first_name', 'last_name']
          },
          {
            model: CourseUnit,
            as: 'units',
            where: { is_active: true },
            required: false,
            order: [['order_number', 'ASC']]
          }
        ]
      });
      
      if (!course) {
        return res.status(404).render('error', {
          title: 'Curso no encontrado',
          error: 'El curso solicitado no existe o no está disponible',
          code: 404
        });
      }
      
      const enrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      const enrollmentCount = await Enrollment.count({
        where: { course_id: courseId, is_active: true }
      });
      
      // Obtener exámenes para cada unidad
      const unitsWithExams = [];
      if (course.units) {
        for (const unit of course.units) {
          const exams = await Exam.findAll({
            where: { unit_id: unit.id, is_active: true }
          });
          
          const unitExams = [];
          for (const exam of exams) {
            const userAttempts = await ExamAttempt.findAll({
              where: { user_id: user.id, exam_id: exam.id },
              order: [['created_at', 'DESC']]
            });
            
            unitExams.push({
              ...exam.toJSON(),
              userAttempts,
              canAttempt: await exam.canUserAttempt(user.id),
              bestScore: userAttempts.length > 0 ? Math.max(...userAttempts.map(a => a.score || 0)) : null
            });
          }
          
          unitsWithExams.push({
            ...unit.toJSON(),
            exams: unitExams
          });
        }
      }
      
      res.render('courses/show', {
        title: course.title,
        course: {
          ...course.toJSON(),
          units: unitsWithExams
        },
        enrollment,
        enrollmentCount,
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
      
      const existingEnrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: courseId }
      });
      
      if (existingEnrollment) {
        req.session.error = 'Ya estás matriculado en este curso';
        return res.redirect(`/courses/${courseId}`);
      }
      
      const course = await Course.findByPk(courseId);
      if (!course || !course.is_active) {
        return res.status(404).render('error', {
          title: 'Curso no encontrado',
          error: 'El curso solicitado no existe',
          code: 404
        });
      }
      
      await Enrollment.create({
        user_id: user.id,
        course_id: courseId
      });
      
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
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        req.session.error = errors.array()[0].msg;
        return res.redirect('/courses');
      }
      
      const { enrollment_code } = req.body;
      const user = req.user;
      
      const code = await EnrollmentCode.findOne({
        where: { 
          code: enrollment_code.toUpperCase(),
          is_active: true
        }
      });
      
      if (!code) {
        req.session.error = 'Código de matrícula inválido';
        return res.redirect('/courses');
      }
      
      if (code.used_count >= code.max_uses) {
        req.session.error = 'Código de matrícula agotado';
        return res.redirect('/courses');
      }
      
      if (code.expires_at && new Date() > code.expires_at) {
        req.session.error = 'Código de matrícula expirado';
        return res.redirect('/courses');
      }
      
      const existingEnrollment = await Enrollment.findOne({
        where: { user_id: user.id, course_id: code.course_id }
      });
      
      if (existingEnrollment) {
        req.session.error = 'Ya estás matriculado en este curso';
        return res.redirect(`/courses/${code.course_id}`);
      }
      
      await code.increment('used_count');
      
      await Enrollment.create({
        user_id: user.id,
        course_id: code.course_id
      });
      
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
        include: [{
          model: Course,
          as: 'course',
          include: [{
            model: User,
            as: 'creator',
            attributes: ['first_name', 'last_name']
          }]
        }],
        order: [['enrolled_at', 'DESC']]
      });
      
      // Obtener estadísticas de exámenes por curso
      const enrollmentsWithStats = [];
      for (const enrollment of enrollments) {
        const courseUnits = await CourseUnit.findAll({
          where: { course_id: enrollment.course_id, is_active: true }
        });
        
        let totalExams = 0;
        let completedExams = 0;
        
        for (const unit of courseUnits) {
          const exams = await Exam.findAll({
            where: { unit_id: unit.id, is_active: true }
          });
          
          totalExams += exams.length;
          
          for (const exam of exams) {
            const bestAttempt = await ExamAttempt.findOne({
              where: { 
                user_id: user.id, 
                exam_id: exam.id,
                passed: true
              },
              order: [['score', 'DESC']]
            });
            
            if (bestAttempt) {
              completedExams++;
            }
          }
        }
        
        enrollmentsWithStats.push({
          ...enrollment.toJSON(),
          totalExams,
          completedExams
        });
      }
      
      res.render('courses/my-courses', {
        title: 'Mis Cursos',
        enrollments: enrollmentsWithStats,
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
      
      const unit = await CourseUnit.findOne({
        where: { id: unitId, course_id: courseId, is_active: true }
      });
      
      if (!unit) {
        return res.status(404).render('error', {
          title: 'Unidad no encontrada',
          error: 'La unidad solicitada no existe',
          code: 404
        });
      }
      
      const course = await Course.findByPk(courseId);
      
      const allUnits = await CourseUnit.findAll({
        where: { course_id: courseId, is_active: true },
        order: [['order_number', 'ASC']]
      });
      
      const currentIndex = allUnits.findIndex(u => u.id === unit.id);
      const nextUnit = allUnits[currentIndex + 1] || null;
      const previousUnit = allUnits[currentIndex - 1] || null;
      
      // Obtener exámenes de la unidad
      const exams = await Exam.findAll({
        where: { unit_id: unit.id, is_active: true }
      });
      
      const examDetails = [];
      for (const exam of exams) {
        const userAttempts = await ExamAttempt.findAll({
          where: { user_id: user.id, exam_id: exam.id },
          order: [['created_at', 'DESC']]
        });
        
        examDetails.push({
          ...exam.toJSON(),
          userAttempts,
          canAttempt: await exam.canUserAttempt(user.id),
          bestScore: userAttempts.length > 0 ? Math.max(...userAttempts.map(a => a.score || 0)) : null,
          hasPassed: userAttempts.some(a => a.passed)
        });
      }
      
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
          course,
          exams: examDetails
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
