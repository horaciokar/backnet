const express = require('express');
const ExamController = require('../controllers/examController');
const { requireRole } = require('../middleware/auth');

const router = express.Router();

// Rutas principales
router.get('/history', ExamController.history);
router.get('/:id', ExamController.show);
router.post('/:id/start', ExamController.start);
router.get('/:examId/take/:attemptId', ExamController.take);
router.post('/:examId/attempt/:attemptId/save-answer', ExamController.saveAnswer);
router.post('/:examId/complete/:attemptId', ExamController.complete);
router.get('/:examId/results/:attemptId', ExamController.results);

module.exports = router;
