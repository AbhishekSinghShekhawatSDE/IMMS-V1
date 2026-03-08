const express = require('express');
const router = express.Router();
const { pool } = require('../db/connection');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

// GET /api/v1/machines/:id/readings - Historical readings for charting
router.get('/:id/readings', async (req, res) => {
    const { from, to, metric, limit = 500 } = req.query;
    const machineId = req.params.id;

    // UUID format check
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(machineId)) {
        return res.status(400).json({ error: 'Invalid machine ID format' });
    }

    // Date validation
    if (from) {
        const parsedFrom = Date.parse(from);
        if (isNaN(parsedFrom)) {
            return res.status(400).json({ error: 'Invalid from date format' });
        }
    }
    if (to) {
        const parsedTo = Date.parse(to);
        if (isNaN(parsedTo)) {
            return res.status(400).json({ error: 'Invalid to date format' });
        }
    }

    let query = `
    SELECT recorded_at as time, metric, value, unit 
    FROM sensor_readings 
    WHERE machine_id = $1
  `;
    const params = [machineId];

    if (from) {
        params.push(from);
        query += ` AND recorded_at >= $${params.length}`;
    } else {
        query += ` AND recorded_at >= NOW() - INTERVAL '1 hour'`;
    }

    if (to) {
        params.push(to);
        query += ` AND recorded_at <= $${params.length}`;
    }

    query += ` ORDER BY recorded_at ASC LIMIT $${params.length + 1}`;
    params.push(limit);

    try {
        const result = await pool.query(query, params);
        res.json({
            machine_id: machineId,
            readings: result.rows
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
