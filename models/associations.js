// models/associations.js
const User = require('./User');
const Course = require('./Course');

function setupAssociations() {
  // Usuario crea cursos
  User.hasMany(Course, { 
    foreignKey: 'created_by', 
    as: 'createdCourses' 
  });
  Course.belongsTo(User, { 
    foreignKey: 'created_by', 
    as: 'creator' 
  });
  
  console.log('✅ Asociaciones de modelos configuradas correctamente');
}

module.exports = { setupAssociations };
