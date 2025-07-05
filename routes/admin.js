const express = require('express');
const AdminController = require('../controllers/adminController');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();

router.use(requireAdmin);

router.get('/dashboard', AdminController.dashboard);
router.get('/users', AdminController.users);
router.post('/users/:userId/toggle-status', AdminController.toggleUserStatus);

module.exports = router;
