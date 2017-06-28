class EventComment < ActiveRecord::Base
  belongs_to :author, class_name: :User, primary_key: :frankiz_id
  belongs_to :event

  def reader_ids
    JSON.parse(read_by || '{}').keys.map(&:to_i)
  end

  def mark_read_by(frankiz_id)
    parsed = JSON.parse(read_by || '{}')
    return true if parsed.key?(frankiz_id.to_s)
    parsed[frankiz_id] ||= Time.current.utc
    update(read_by: parsed.to_json)
  end
end
