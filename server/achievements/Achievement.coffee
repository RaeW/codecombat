mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/achievement'
log = require 'winston'
utils = require '../../app/core/utils'
plugins = require('../plugins/plugins')
AchievablePlugin = require '../plugins/achievements'
TreemaUtils = require '../../bower_components/treema/treema-utils.js'

# `pre` and `post` are not called for update operations executed directly on the database,
# including `Model.update`,`.findByIdAndUpdate`,`.findOneAndUpdate`, `.findOneAndRemove`,and `.findByIdAndRemove`.order
# to utilize `pre` or `post` middleware, you should `find()` the document, and call the `init`, `validate`, `save`,
# or `remove` functions on the document. See [explanation](http://github.com/LearnBoost/mongoose/issues/964).

AchievementSchema = new mongoose.Schema({
  userField: String
}, {strict: false})

AchievementSchema.index(
  {
    _fts: 'text'
    _ftsx: 1
  },
  {
    name: 'search index'
    sparse: true
    weights: {name: 1}
    default_language: 'english'
    'language_override': 'language'
    'textIndexVersion': 2
  })
AchievementSchema.index({i18nCoverage: 1}, {name: 'translation coverage index', sparse: true})
AchievementSchema.index({slug: 1}, {name: 'slug index', sparse: true, unique: true})

AchievementSchema.methods.objectifyQuery = ->
  try
    @set('query', JSON.parse(@get('query'))) if typeof @get('query') == 'string'
  catch error
    log.error "Couldn't convert query string to object because of #{error}"
    @set('query', {})

AchievementSchema.methods.stringifyQuery = ->
  @set('query', JSON.stringify(@get('query'))) if typeof @get('query') != 'string'

AchievementSchema.methods.getExpFunction = ->
  func = @get('function') ? {}
  TreemaUtils.populateDefaults(func, jsonschema.properties.function)
  return utils.functionCreators[func.kind](func.parameters) if func.kind of utils.functionCreators

AchievementSchema.statics.jsonschema = jsonschema
AchievementSchema.statics.earnedAchievements = {}

# Reloads all achievements into memory.
# TODO might want to tweak this to only load new achievements
AchievementSchema.statics.loadAchievements = (done) ->
  AchievementSchema.statics.resetAchievements()
  Achievement = require('../achievements/Achievement')
  query = Achievement.find({collection: {$ne: 'level.sessions'}})
  query.exec (err, docs) ->
    _.each docs, (achievement) ->
      category = achievement.get 'collection'
      AchievementSchema.statics.earnedAchievements[category] = [] unless category of AchievementSchema.statics.earnedAchievements
      AchievementSchema.statics.earnedAchievements[category].push achievement
    done?(AchievementSchema.statics.earnedAchievements)

AchievementSchema.statics.getLoadedAchievements = ->
  AchievementSchema.statics.earnedAchievements

AchievementSchema.statics.resetAchievements = ->
  delete AchievementSchema.statics.earnedAchievements[category] for category of AchievementSchema.statics.earnedAchievements

# Queries are stored as JSON strings, objectify them upon loading
AchievementSchema.post 'init', (doc) -> doc.objectifyQuery()

AchievementSchema.pre 'save', (next) ->
  @stringifyQuery()
  next()

# Reload achievements upon save
AchievementSchema.post 'save', -> @constructor.loadAchievements()

AchievementSchema.plugin(plugins.NamedPlugin)
AchievementSchema.plugin(plugins.SearchablePlugin, {searchable: ['name']})
AchievementSchema.plugin plugins.TranslationCoveragePlugin

module.exports = Achievement = mongoose.model('Achievement', AchievementSchema, 'achievements')

AchievementSchema.statics.loadAchievements()
