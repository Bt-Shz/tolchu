ParameterType(
  name: "credits",
  regexp: /\d{1,3}(?:,\d{3})+|\d+/,
  transformer: ->(amount) { amount.delete(",").to_i }
)

ParameterType(
  name: "signed_credits",
  regexp: /[+-](?:\d{1,3}(?:,\d{3})+|\d+)/,
  transformer: ->(amount) { amount.delete(",").to_i }
)

ParameterType(
  name: "page",
  regexp: /the feed|the sign up page|the sign in page|my wallet|my studio|the new market page|the how it works page/,
  transformer: ->(name) { name }
)
