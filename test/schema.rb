ActiveRecord::Schema.define do
  self.verbose = false

  create_table :imports, force: true do |t|
    t.integer 'kind', null: false
    t.string 'state', default: 'waiting', null: false
    t.json 'notes', default: []
    t.json 'meta', default: {}
    t.timestamps
  end
end
