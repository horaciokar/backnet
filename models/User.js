const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  email: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
      len: [5, 100]
    }
  },
  
  password: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [6, 255]
    }
  },
  
  first_name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    validate: {
      len: [2, 50]
    }
  },
  
  last_name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    validate: {
      len: [2, 50]
    }
  },
  
  role: {
    type: DataTypes.ENUM('admin', 'instructor', 'student'),
    allowNull: false,
    defaultValue: 'student'
  },
  
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  profile_picture: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  
  last_login: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'users',
  
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    },
    
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    }
  }
});

// Métodos de instancia
User.prototype.validatePassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

User.prototype.getFullName = function() {
  return `${this.first_name} ${this.last_name}`;
};

User.prototype.toJSON = function() {
  const values = Object.assign({}, this.get());
  delete values.password;
  return values;
};

// Métodos de clase
User.findByEmail = async function(email) {
  return await this.findOne({ where: { email } });
};

User.findActiveUsers = async function() {
  return await this.findAll({ 
    where: { is_active: true },
    order: [['created_at', 'DESC']]
  });
};

User.findByRole = async function(role) {
  return await this.findAll({ 
    where: { role, is_active: true },
    order: [['first_name', 'ASC']]
  });
};

module.exports = User;
