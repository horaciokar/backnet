const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CourseUnit = sequelize.define('CourseUnit', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  course_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'courses',
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
  
  content: {
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
  
  content_type: {
    type: DataTypes.ENUM('text', 'video', 'pdf', 'lab', 'mixed'),
    allowNull: false,
    defaultValue: 'text'
  },
  
  video_url: {
    type: DataTypes.STRING(255),
    allowNull: true,
    validate: {
      isUrl: true
    }
  },
  
  duration_minutes: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0
    }
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'course_units'
});

module.exports = CourseUnit;
