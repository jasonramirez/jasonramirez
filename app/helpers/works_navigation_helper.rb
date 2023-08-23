module WorksNavigationHelper
  def work_link(work)
    if work[:protected] == true
      "/protected_works/#{work[:name]}"
    else
      "/works/#{work[:name]}"
    end
  end
end
