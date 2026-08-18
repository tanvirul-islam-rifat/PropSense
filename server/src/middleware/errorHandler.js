export const notFound = (req, res) => {
  res.status(404).json({ message: `Route not found - ${req.originalUrl}` });
};

export const errorHandler = (err, req, res, next) => {
  const statusCode = res.statusCode !== 200 ? res.statusCode : err.statusCode || 500;
  res.status(statusCode).json({
    message: err.message || 'Server error',
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
};
