class UpdateSidebarTypes < ActiveRecord::Migration[7.2]
  def up
    legacy_types = Sidebar.distinct.pluck(:type)

    legacy_types.each do | legacy_type |
      Sidebar.where(type: legacy_type).update_all(type: "#{legacy_type}::#{legacy_type}")
    end
  end

  def down
    modern_types = Sidebar.distinct.pluck(:type)

    modern_types.each do | modern_type |
      legacy_type = modern_type.split('::').last
      Sidebar.where(type: modern_type).update_all(type: legacy_type)
    end
  end
end
