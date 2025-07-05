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
