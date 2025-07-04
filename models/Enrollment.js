const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Enrollment = sequelize.define('Enrollment', {
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
  
  course_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'courses',
      key: 'id'
    }
  },
  
  enrolled_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  
  progress: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0,
      max: 100
    }
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'enrollments'
});

const EnrollmentCode = sequelize.define('EnrollmentCode', {
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
  
  code: {
    type: DataTypes.STRING(20),
    allowNull: false,
    unique: true,
    validate: {
      len: [6, 20]
    }
  },
  
  max_uses: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 50
  },
  
  used_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'enrollment_codes'
});

module.exports = { Enrollment, EnrollmentCode };
