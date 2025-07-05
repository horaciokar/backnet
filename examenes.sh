#!/bin/bash

# Script para desarrollar sistema completo de exámenes
echo "📝 Desarrollando sistema completo de exámenes..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. ACTUALIZAR MODELOS DE EXÁMENES
print_status "Actualizando modelos de exámenes..."
cat > models/Exam.js << 'EOF'
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Exam = sequelize.define('Exam', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  unit_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'course_units',
      key: 'id'
    }
  },
  
  title: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: {
      len: [3, 100]
    }
  },
  
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  
  questions_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
    validate: {
      min: 1,
      max: 50
    }
  },
  
  passing_score: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 70,
    validate: {
      min: 0,
      max: 100
    }
  },
  
  time_limit_minutes: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 30,
    validate: {
      min: 5,
      max: 180
    }
  },
  
  max_attempts: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 3,
    validate: {
      min: 1,
      max: 10
    }
  },
  
  shuffle_questions: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  shuffle_options: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'exams'
});

const Question = sequelize.define('Question', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  exam_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'exams',
      key: 'id'
    }
  },
  
  question_text: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      len: [10, 1000]
    }
  },
  
  option_a: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [1, 255]
    }
  },
  
  option_b: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [1, 255]
    }
  },
  
  option_c: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [1, 255]
    }
  },
  
  option_d: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [1, 255]
    }
  },
  
  correct_answer: {
    type: DataTypes.ENUM('A', 'B', 'C', 'D'),
    allowNull: false
  },
  
  explanation: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  
  order_number: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1
    }
  },
  
  difficulty: {
    type: DataTypes.ENUM('easy', 'medium', 'hard'),
    allowNull: false,
    defaultValue: 'medium'
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'questions'
});

const ExamAttempt = sequelize.define('ExamAttempt', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  
  exam_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'exams',
      key: 'id'
    }
  },
  
  started_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  
  completed_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  
  answers: {
    type: DataTypes.JSON,
    allowNull: true
  },
  
  score: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 0,
      max: 100
    }
  },
  
  correct_answers: {
    type: DataTypes.INTEGER,
    allowNull: true,
    defaultValue: 0
  },
  
  total_questions: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  
  passed: {
    type: DataTypes.BOOLEAN,
    allowNull: true
  },
  
  time_taken_minutes: {
    type: DataTypes.INTEGER,
    allowNull: true
  }
}, {
  tableName: 'exam_attempts'
});

// Métodos para Exam
Exam.prototype.getUserAttempts = async function(userId) {
  return await ExamAttempt.findAll({
    where: { exam_id: this.id, user_id: userId },
    order: [['created_at', 'DESC']]
  });
};

Exam.prototype.canUserAttempt = async function(userId) {
  const attempts = await this.getUserAttempts(userId);
  return attempts.length < this.max_attempts;
};

Exam.prototype.getQuestions = async function(shuffle = false) {
  let questions = await Question.findAll({
    where: { exam_id: this.id, is_active: true },
    order: shuffle ? sequelize.random() : [['order_number', 'ASC']]
  });
  
  if (shuffle && this.shuffle_options) {
    questions = questions.map(q => q.shuffleOptions());
  }
  
  return questions;
};

// Métodos para Question
Question.prototype.checkAnswer = function(answer) {
  return this.correct_answer === answer.toUpperCase();
};

Question.prototype.getOptions = function() {
  return {
    A: this.option_a,
    B: this.option_b,
    C: this.option_c,
    D: this.option_d
  };
};

Question.prototype.shuffleOptions = function() {
  const options = [
    { key: 'A', value: this.option_a },
    { key: 'B', value: this.option_b },
    { key: 'C', value: this.option_c },
    { key: 'D', value: this.option_d }
  ];
  
  // Shuffle array
  for (let i = options.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [options[i], options[j]] = [options[j], options[i]];
  }
  
  // Update correct answer mapping
  const correctOption = options.find(opt => opt.key === this.correct_answer);
  const newCorrectIndex = options.indexOf(correctOption);
  const newCorrectLetter = ['A', 'B', 'C', 'D'][newCorrectIndex];
  
  return {
    ...this.toJSON(),
    option_a: options[0].value,
    option_b: options[1].value,
    option_c: options[2].value,
    option_d: options[3].value,
    correct_answer: newCorrectLetter,
    original_mapping: options
  };
};

// Métodos para ExamAttempt
ExamAttempt.prototype.calculateScore = async function() {
  if (!this.answers || !this.completed_at) return;
  
  const questions = await Question.findAll({
    where: { exam_id: this.exam_id, is_active: true }
  });
  
  let correctCount = 0;
  
  for (const question of questions) {
    const userAnswer = this.answers[question.id];
    if (userAnswer && question.checkAnswer(userAnswer)) {
      correctCount++;
    }
  }
  
  const score = Math.round((correctCount / questions.length) * 100);
  const exam = await Exam.findByPk(this.exam_id);
  
  await this.update({
    score,
    correct_answers: correctCount,
    total_questions: questions.length,
    passed: score >= exam.passing_score
  });
  
  return this;
};

ExamAttempt.prototype.getDuration = function() {
  if (!this.started_at || !this.completed_at) return null;
  
  const diff = new Date(this.completed_at) - new Date(this.started_at);
  return Math.round(diff / (1000 * 60)); // en minutos
};

module.exports = { Exam, Question, ExamAttempt };
EOF

# 2. CREAR CONTROLADOR COMPLETO DE EXÁMENES
print_status "Creando controlador de exámenes..."
cat > controllers/examController.js << 'EOF'
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
EOF

# 3. CREAR RUTAS DE EXÁMENES
print_status "Creando rutas de exámenes..."
cat > routes/exams.js << 'EOF'
const express = require('express');
const ExamController = require('../controllers/examController');
const { requireRole } = require('../middleware/auth');

const router = express.Router();

// Rutas principales
router.get('/history', ExamController.history);
router.get('/:id', ExamController.show);
router.post('/:id/start', ExamController.start);
router.get('/:examId/take/:attemptId', ExamController.take);
router.post('/:examId/attempt/:attemptId/save-answer', ExamController.saveAnswer);
router.post('/:examId/complete/:attemptId', ExamController.complete);
router.get('/:examId/results/:attemptId', ExamController.results);

module.exports = router;
EOF

print_status "✅ Sistema de exámenes desarrollado!"
echo ""
echo "🎯 Funcionalidades implementadas:"
echo "   ✓ Ver exámenes disponibles"
echo "   ✓ Iniciar exámenes con cronómetro"
echo "   ✓ Guardar respuestas automáticamente"
echo "   ✓ Completar y calificar automáticamente"
echo "   ✓ Ver resultados detallados"
echo "   ✓ Historial de intentos"
echo "   ✓ Control de intentos máximos"
echo "   ✓ Progreso basado en exámenes aprobados"
echo ""
echo "📋 Rutas de exámenes:"
echo "   GET  /exams/:id - Ver examen"
echo "   POST /exams/:id/start - Iniciar examen"
echo "   GET  /exams/:examId/take/:attemptId - Tomar examen"
echo "   POST /exams/:examId/attempt/:attemptId/save-answer - Guardar respuesta"
echo "   POST /exams/:examId/complete/:attemptId - Completar examen"
echo "   GET  /exams/:examId/results/:attemptId - Ver resultados"
echo "   GET  /exams/history - Historial de exámenes"
echo ""
echo "🚀 Para probar:"
echo "   1. Reiniciar aplicación: npm run dev"
echo "   2. Matricularse en un curso"
echo "   3. Ir a una unidad y buscar enlace al examen"
echo "   4. ¡Tomar el examen!"
echo ""
print_warning "⚠️  Próximo paso: Crear las vistas del sistema de exámenes"
