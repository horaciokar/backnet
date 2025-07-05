const express = require('express');
const DashboardController = require('../controllers/dashboardController');

const router = express.Router();

router.get('/', DashboardController.index);
router.get('/progress', DashboardController.progressDetail);

module.exports = router;
