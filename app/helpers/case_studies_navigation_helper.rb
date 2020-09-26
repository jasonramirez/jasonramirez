module CaseStudiesNavigationHelper
  def case_study_link(case_study)
    if case_study[:protected] == true
      "/protected_case_studies/#{case_study[:name]}"
    else
      "/case_studies/#{case_study[:name]}"
    end
  end
end
