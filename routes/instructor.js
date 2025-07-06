const express = require('express');
const InstructorController = require('../controllers/instructorController');
const { validateInstructorPermission } = require('../middleware/security');

const router = express.Router();

// Aplicar middleware de instructor
router.use(validateInstructorPermission);

// Rutas principales
router.get('/dashboard', InstructorController.dashboard);
router.get('/students', InstructorController.students);
router.get('/exams', InstructorController.exams);
router.get('/reports', InstructorController.reports);

module.exports = router;
