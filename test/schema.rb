ActiveRecord::Schema.define do
  self.verbose = false

  create_table :imports, force: true do |t|
    t.integer 'kind', null: false
    t.integer 'state', default: 0, null: false
    t.json 'notes', default: []
    t.timestamps
  end
end
