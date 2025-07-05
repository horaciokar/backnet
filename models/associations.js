function setupAssociations() {
  try {
    console.log('🔗 Configurando asociaciones de modelos...');
    
    // Importar modelos
    const User = require('./User');
    const Course = require('./Course');
    const CourseUnit = require('./CourseUnit');
    const { Enrollment, EnrollmentCode } = require('./Enrollment');
    
    // Usuario crea cursos
    User.hasMany(Course, { 
      foreignKey: 'created_by', 
      as: 'createdCourses' 
    });
    Course.belongsTo(User, { 
      foreignKey: 'created_by', 
      as: 'creator' 
    });
    
    // Curso tiene unidades
    Course.hasMany(CourseUnit, { 
      foreignKey: 'course_id', 
      as: 'units' 
    });
    CourseUnit.belongsTo(Course, { 
      foreignKey: 'course_id', 
      as: 'course' 
    });
    
    // Usuario tiene matrículas
    User.hasMany(Enrollment, { 
      foreignKey: 'user_id', 
      as: 'enrollments' 
    });
    Enrollment.belongsTo(User, { 
      foreignKey: 'user_id', 
      as: 'student' 
    });
    
    // Curso tiene matrículas
    Course.hasMany(Enrollment, { 
      foreignKey: 'course_id', 
      as: 'enrollments' 
    });
    Enrollment.belongsTo(Course, { 
      foreignKey: 'course_id', 
      as: 'course' 
    });
    
    // Curso tiene códigos de matrícula
    Course.hasMany(EnrollmentCode, { 
      foreignKey: 'course_id', 
      as: 'enrollmentCodes' 
    });
    EnrollmentCode.belongsTo(Course, { 
      foreignKey: 'course_id', 
      as: 'course' 
    });
    
    console.log('✅ Asociaciones configuradas correctamente');
  } catch (error) {
    console.error('❌ Error configurando asociaciones:', error.message);
  }
}

module.exports = { setupAssociations };
