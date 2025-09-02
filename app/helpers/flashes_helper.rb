module FlashesHelper
  def user_facing_flashes
    flash.to_hash.slice("alert", "error", "notice")
  end

  def flash_icon(flash_type)
    icon_name = case flash_type
                 when 'notice' then 'icon-checkmark.svg'
                 when 'alert' then 'icon-exclamation.svg'
                 when 'error' then 'icon-x.svg'
                 else 'icon-info.svg'
                 end
    inline_svg(icon_name)
  end
end
