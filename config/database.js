const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    
    // Configuración de pool de conexiones optimizada para free tier
    pool: {
      max: 5,        // Máximo 5 conexiones simultáneas
      min: 0,        // Mínimo 0 conexiones
      acquire: 30000, // Tiempo máximo para obtener conexión
      idle: 10000    // Tiempo máximo inactivo antes de cerrar
    },
    
    // Configuración de logging
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    
    // Configuración de zona horaria
    timezone: '-05:00', // Colombia timezone
    
    // Configuración adicional
    define: {
      timestamps: true,
      underscored: true,
      freezeTableName: true,
      charset: 'utf8mb4',
      collate: 'utf8mb4_unicode_ci'
    },
    
    // Configuración de dialecto MySQL
    dialectOptions: {
      charset: 'utf8mb4',
      dateStrings: true,
      typeCast: true
    }
  }
);

// Función para probar la conexión
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conexión a la base de datos establecida correctamente.');
    return true;
  } catch (error) {
    console.error('❌ Error al conectar con la base de datos:', error.message);
    return false;
  }
}

// Función para sincronizar modelos
async function syncDatabase(force = false) {
  try {
    await sequelize.sync({ force });
    console.log('✅ Modelos sincronizados con la base de datos.');
  } catch (error) {
    console.error('❌ Error al sincronizar modelos:', error.message);
    throw error;
  }
}

// Función para cerrar conexión
async function closeConnection() {
  try {
    await sequelize.close();
    console.log('✅ Conexión a la base de datos cerrada.');
  } catch (error) {
    console.error('❌ Error al cerrar la conexión:', error.message);
  }
}

module.exports = {
  sequelize,
  testConnection,
  syncDatabase,
  closeConnection
};
