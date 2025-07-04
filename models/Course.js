const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Course = sequelize.define('Course', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
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
    allowNull: false,
    validate: {
      len: [10, 2000]
    }
  },
  
  short_description: {
    type: DataTypes.STRING(255),
    allowNull: true,
    validate: {
      len: [0, 255]
    }
  },
  
  duration_hours: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0,
      max: 1000
    }
  },
  
  difficulty_level: {
    type: DataTypes.ENUM('beginner', 'intermediate', 'advanced'),
    allowNull: false,
    defaultValue: 'beginner'
  },
  
  category: {
    type: DataTypes.ENUM('networks', 'security', 'both'),
    allowNull: false,
    defaultValue: 'both'
  },
  
  thumbnail: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  is_public: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  
  max_students: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1
    }
  },
  
  created_by: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  }
}, {
  tableName: 'courses',
  
  indexes: [
    {
      fields: ['title']
    },
    {
      fields: ['category']
    },
    {
      fields: ['is_active']
    },
    {
      fields: ['created_by']
    }
  ]
});

// Métodos de instancia
Course.prototype.getEnrollmentCount = async function() {
  const { Enrollment } = require('./Enrollment');
  return await Enrollment.count({
    where: { course_id: this.id }
  });
};

Course.prototype.getUnitsCount = async function() {
  const CourseUnit = require('./CourseUnit');
  return await CourseUnit.count({
    where: { course_id: this.id }
  });
};

// Métodos de clase
Course.findActive = async function() {
  return await this.findAll({
    where: { is_active: true },
    order: [['created_at', 'DESC']]
  });
};

Course.findByCategory = async function(category) {
  return await this.findAll({
    where: { 
      category,
      is_active: true 
    },
    order: [['title', 'ASC']]
  });
};

module.exports = Course;
