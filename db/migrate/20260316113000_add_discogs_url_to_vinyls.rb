class AddDiscogsUrlToVinyls < ActiveRecord::Migration[8.1]
  def change
    add_column :vinyls, :discogs_url, :string
  end
end
