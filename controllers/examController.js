const { validationResult } = require('express-validator');
const { Exam, Question, ExamAttempt } = require('../models/Exam');
const CourseUnit = require('../models/CourseUnit');
const Course = require('../models/Course');
const { Enrollment } = require('../models/Enrollment');
const User = require('../models/User');

class ExamController {
  
  // Mostrar examen antes de iniciar
  static async show(req, res) {
    try {
      const examId = req.params.id;
      const user = req.user;
      
      const exam = await Exam.findByPk(examId);
      
      if (!exam || !exam.is_active) {
        return res.status(404).render('error', {
          title: 'Examen no encontrado',
          error: 'El examen solicitado no existe',
          code: 404
        });
      }
      
      // Obtener unidad y curso
      const unit = await CourseUnit.findByPk(exam.unit_id);
      const course = await Course.findByPk(unit.course_id);
      
      // Verificar matrícula (solo para estudiantes)
      if (user.role === 'student') {
        const enrollment = await Enrollment.findOne({
          where: { 
            user_id: user.id, 
            course_id: unit.course_id 
          }
        });
        
        if (!enrollment) {
          return res.status(403).render('error', {
            title: 'Acceso denegado',
            error: 'Debes estar matriculado en el curso para acceder a este examen',
            code: 403
          });
        }
      }
      
      // Obtener intentos del usuario
      const attempts = await exam.getUserAttempts(user.id);
      const canAttempt = await exam.canUserAttempt(user.id);
      
      // Verificar si hay un intento en progreso
      const currentAttempt = attempts.find(attempt => !attempt.completed_at);
      
      res.render('exams/show', {
        title: `Examen: ${exam.title}`,
        exam,
        unit,
        course,
        attempts,
        canAttempt,
        currentAttempt,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar examen:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el examen',
        code: 500
      });
    }
  }
  
  // Iniciar examen
  static async start(req, res) {
    try {
      const examId = req.params.id;
      const user = req.user;
      
      const exam = await Exam.findByPk(examId);
      
      if (!exam || !exam.is_active) {
        return res.status(404).render('error', {
          title: 'Examen no encontrado',
          error: 'El examen solicitado no existe',
          code: 404
        });
      }
      
      // Verificar si puede intentar
      const canAttempt = await exam.canUserAttempt(user.id);
      if (!canAttempt) {
        req.session.error = 'Has agotado el número máximo de intentos para este examen';
        return res.redirect(`/exams/${examId}`);
      }
      
      // Verificar si hay un intento en progreso
      const currentAttempt = await ExamAttempt.findOne({
        where: {
          user_id: user.id,
          exam_id: examId,
          completed_at: null
        }
      });
      
      if (currentAttempt) {
        return res.redirect(`/exams/${examId}/take/${currentAttempt.id}`);
      }
      
      // Obtener preguntas
      const questions = await exam.getQuestions(exam.shuffle_questions);
      
      // Crear nuevo intento
      const attempt = await ExamAttempt.create({
        user_id: user.id,
        exam_id: examId,
        total_questions: questions.length,
        started_at: new Date()
      });
      
      res.redirect(`/exams/${examId}/take/${attempt.id}`);
      
    } catch (error) {
      console.error('Error al iniciar examen:', error);
      req.session.error = 'Error al iniciar el examen';
      res.redirect(`/exams/${req.params.id}`);
    }
  }
  
  // Tomar examen
  static async take(req, res) {
    try {
      const { examId, attemptId } = req.params;
      const user = req.user;
      
      const attempt = await ExamAttempt.findByPk(attemptId);
      
      if (!attempt || attempt.user_id !== user.id || attempt.exam_id !== parseInt(examId)) {
        return res.status(404).render('error', {
          title: 'Intento no encontrado',
          error: 'El intento de examen no existe',
          code: 404
        });
      }
      
      // Verificar si ya fue completado
      if (attempt.completed_at) {
        return res.redirect(`/exams/${examId}/results/${attemptId}`);
      }
      
      const exam = await Exam.findByPk(examId);
      const unit = await CourseUnit.findByPk(exam.unit_id);
      const course = await Course.findByPk(unit.course_id);
      
      // Verificar tiempo límite
      const timeElapsed = Math.floor((new Date() - new Date(attempt.started_at)) / (1000 * 60));
      if (timeElapsed >= exam.time_limit_minutes) {
        // Auto-completar por tiempo
        await attempt.update({
          completed_at: new Date(),
          time_taken_minutes: exam.time_limit_minutes
        });
        
        await attempt.calculateScore();
        
        return res.redirect(`/exams/${examId}/results/${attemptId}`);
      }
      
      // Obtener preguntas
      const questions = await exam.getQuestions(exam.shuffle_questions);
      
      // Tiempo restante
      const timeRemaining = exam.time_limit_minutes - timeElapsed;
      
      res.render('exams/take', {
        title: `Tomando: ${exam.title}`,
        exam,
        attempt,
        questions,
        timeRemaining,
        course,
        unit,
        currentAnswers: attempt.answers || {},
        user
      });
      
    } catch (error) {
      console.error('Error al tomar examen:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el examen',
        code: 500
      });
    }
  }
  
  // Guardar respuesta (AJAX)
  static async saveAnswer(req, res) {
    try {
      const { examId, attemptId } = req.params;
      const { questionId, answer } = req.body;
      const user = req.user;
      
      const attempt = await ExamAttempt.findByPk(attemptId);
      
      if (!attempt || attempt.user_id !== user.id || attempt.exam_id !== parseInt(examId)) {
        return res.status(404).json({ success: false, message: 'Intento no encontrado' });
      }
      
      if (attempt.completed_at) {
        return res.status(400).json({ success: false, message: 'Examen ya completado' });
      }
      
      // Actualizar respuestas
      const currentAnswers = attempt.answers || {};
      currentAnswers[questionId] = answer;
      
      await attempt.update({ answers: currentAnswers });
      
      res.json({ success: true, message: 'Respuesta guardada' });
      
    } catch (error) {
      console.error('Error al guardar respuesta:', error);
      res.status(500).json({ success: false, message: 'Error del servidor' });
    }
  }
  
  // Completar examen
  static async complete(req, res) {
    try {
      const { examId, attemptId } = req.params;
      const user = req.user;
      
      const attempt = await ExamAttempt.findByPk(attemptId);
      
      if (!attempt || attempt.user_id !== user.id || attempt.exam_id !== parseInt(examId)) {
        return res.status(404).render('error', {
          title: 'Intento no encontrado',
          error: 'El intento de examen no existe',
          code: 404
        });
      }
      
      if (attempt.completed_at) {
        return res.redirect(`/exams/${examId}/results/${attemptId}`);
      }
      
      // Calcular tiempo tomado
      const timeElapsed = Math.floor((new Date() - new Date(attempt.started_at)) / (1000 * 60));
      
      // Completar intento
      await attempt.update({
        completed_at: new Date(),
        time_taken_minutes: timeElapsed
      });
      
      // Calcular puntaje
      await attempt.calculateScore();
      
      // Actualizar progreso si aprobó
      if (attempt.passed) {
        const exam = await Exam.findByPk(examId);
        const unit = await CourseUnit.findByPk(exam.unit_id);
        
        const enrollment = await Enrollment.findOne({
          where: { 
            user_id: user.id, 
            course_id: unit.course_id 
          }
        });
        
        if (enrollment) {
          // Actualizar progreso básico
          await enrollment.increment('progress', { by: 10 });
        }
      }
      
      res.redirect(`/exams/${examId}/results/${attemptId}`);
      
    } catch (error) {
      console.error('Error al completar examen:', error);
      req.session.error = 'Error al completar el examen';
      res.redirect(`/exams/${req.params.examId}`);
    }
  }
  
  // Mostrar resultados
  static async results(req, res) {
    try {
      const { examId, attemptId } = req.params;
      const user = req.user;
      
      const attempt = await ExamAttempt.findByPk(attemptId);
      
      if (!attempt || attempt.user_id !== user.id || attempt.exam_id !== parseInt(examId)) {
        return res.status(404).render('error', {
          title: 'Resultado no encontrado',
          error: 'El resultado del examen no existe',
          code: 404
        });
      }
      
      if (!attempt.completed_at) {
        return res.redirect(`/exams/${examId}/take/${attemptId}`);
      }
      
      const exam = await Exam.findByPk(examId);
      const unit = await CourseUnit.findByPk(exam.unit_id);
      const course = await Course.findByPk(unit.course_id);
      
      // Obtener respuestas detalladas
      const questions = await Question.findAll({
        where: { exam_id: examId, is_active: true },
        order: [['order_number', 'ASC']]
      });
      
      const questionResults = questions.map(question => {
        const userAnswer = attempt.answers ? attempt.answers[question.id] : null;
        const isCorrect = question.checkAnswer(userAnswer || '');
        
        return {
          question,
          userAnswer,
          isCorrect,
          correctAnswer: question.correct_answer
        };
      });
      
      res.render('exams/results', {
        title: `Resultados: ${exam.title}`,
        exam,
        attempt,
        questionResults,
        course,
        unit,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar resultados:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar los resultados',
        code: 500
      });
    }
  }
  
  // Historial de intentos
  static async history(req, res) {
    try {
      const user = req.user;
      
      const attempts = await ExamAttempt.findAll({
        where: { user_id: user.id },
        order: [['created_at', 'DESC']]
      });
      
      // Obtener información adicional para cada intento
      const attemptsWithDetails = [];
      for (const attempt of attempts) {
        const exam = await Exam.findByPk(attempt.exam_id);
        const unit = await CourseUnit.findByPk(exam.unit_id);
        const course = await Course.findByPk(unit.course_id);
        
        attemptsWithDetails.push({
          ...attempt.toJSON(),
          exam,
          unit,
          course
        });
      }
      
      res.render('exams/history', {
        title: 'Historial de Exámenes',
        attempts: attemptsWithDetails,
        user
      });
      
    } catch (error) {
      console.error('Error al mostrar historial:', error);
      res.status(500).render('error', {
        title: 'Error',
        error: 'Error al cargar el historial',
        code: 500
      });
    }
  }
}

module.exports = ExamController;
