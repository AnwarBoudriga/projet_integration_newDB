// Valide req[source] avec un schéma zod; résultat dans req.valid
// (Express 5: req.query est en lecture seule, d'où req.valid)
module.exports = (schema, source = 'body') => (req, _res, next) => {
  req.valid = schema.parse(req[source]);
  next();
};
