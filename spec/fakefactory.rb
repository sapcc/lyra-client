class FakeFactory

  def self.automation(params = {})
    {"type"=>"Chef",
     "name"=>"test",
     "project_id"=>"1d1ad583e98c4913a0226feac0f010f9",
     "repository"=>"http://adfadf.com",
     "repository_revision"=>"master",
     "timeout"=>3600,
     "tags"=> {},
       "created_at"=>"2016-09-14T10:16:32.219Z",
      "updated_at"=>"2016-09-14T10:17:15.683Z",
      "run_list"=>["afdadsf"],
      "chef_attributes"=>{},
      "log_level"=>"",
      "chef_version"=>"",
      "path"=>nil,
    "arguments"=>nil,
    "environment"=>nil}.merge(params)
  end

  def self.unprocessble_automation()
    {errors: {type: ["can't be blank"]}}.to_json #"{\"errors\":{\"type\":[\"can't be blank\"]}}"
  end

end
