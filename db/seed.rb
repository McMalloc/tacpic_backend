require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require_relative '../helper/functions'

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

Taxonomy.create(
    taxonomy: 'misc'
)

# Product.unrestrict_primary_key
# Product.create(
#     customisable: true,
#     identifier: "graphic",
#     reduced_var: true
# )
# Product.create(
#     customisable: true,
#     identifier: "graphic_nobraille",
#     reduced_var: true
# )
# Product.create(
#     customisable: true,
#     identifier: "postage",
#     reduced_var: true
# )
# Product.create(
#     customisable: true,
#     identifier: "packaging",
#     reduced_var: false
# )
