class ChangeUploadLogColumnTypeInAssignments < ActiveRecord::Migration[6.0]
  def change
    change_column(:assignments, :upload_log, :longtext)
  end
end
