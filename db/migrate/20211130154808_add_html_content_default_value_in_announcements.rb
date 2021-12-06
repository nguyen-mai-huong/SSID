class AddHtmlContentDefaultValueInAnnouncements < ActiveRecord::Migration[6.0]
  def change
    change_column_null :announcements, :html_content, true
    change_column_null :announcements, :announceable_type, true
  end
end
