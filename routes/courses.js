const express = require('express');
const { body } = require('express-validator');
const CourseController = require('../controllers/courseController');
const { requireRole } = require('../middleware/auth');

const router = express.Router();

// Validaciones
const enrollCodeValidation = [
  body('enrollment_code')
    .isLength({ min: 6, max: 20 })
    .withMessage('El código debe tener entre 6 y 20 caracteres')
    .trim()
];

// Rutas principales
router.get('/', CourseController.index);
router.get('/my-courses', CourseController.myCourses);

// Rutas de matrícula
router.post('/enroll-with-code', requireRole('student'), enrollCodeValidation, CourseController.enrollWithCode);
router.post('/:id/enroll', requireRole('student'), CourseController.enroll);

// Rutas de curso específico
router.get('/:id', CourseController.show);
router.get('/:courseId/unit/:unitId', CourseController.showUnit);

module.exports = router;
