{EventEmitter} = require 'events'
Record = require './record'
mongodb = require 'mongodb'

class Database extends EventEmitter
  collection: null

  # Public: Create or open a Database with path to {filename}
  constructor: (uri='mongodb://localhost:27017/breakpad', collection='record') ->
    mongodb.connect uri, (err, conn) =>
      throw new Error("Cannot connect: #{uri}") if err?

      @collection = conn.collection collection
      @emit.bind(this, 'load')

  # Public: Saves a record to database.
  saveRecord: (record, callback) ->
    _id = record.id
    delete record.id

    @collection.update {_id: _id}, record, {upsert: true}, callback

  # Public: Restore a record from database according to its id.
  restoreRecord: (id, callback) ->
    @collection.findOne {_id: id}, (err, doc) ->
      return callback err if err
      return callback new Error("Record is not in database") unless doc?

      callback null, Record.unserialize(id, doc)

  # Public: Returns all records as an array.
  getAllRecords: (callback) ->
    cursor = @collection.find {}, {sort: {_id: -1}}
    cursor.toArray (err, docs) ->
      return callback err if err
      records = docs.map (doc) -> Record.unserialize(doc._id, doc)
      callback null, records

module.exports = Database
