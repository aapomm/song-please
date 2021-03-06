require 'rubygems'
require 'google/api_client'
require 'rest-client'
require 'json'
require 'sinatra'

DEVELOPER_KEY = ENV['GOOGLE_API_KEY']
YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'

def get_service
  client = Google::APIClient.new(
    :key => DEVELOPER_KEY,
    :authorization => nil,
    :application_name => 'song-please',
    :application_version => '0.0.0'
  )
  youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)

  return client, youtube
end

def query_in_youtube query_string
  client, youtube = get_service

  begin
    results = client.execute!(
      :api_method => youtube.search.list,
      :parameters => {
        :part => 'snippet',
        :q => query_string,
        :maxResults => 1
      }
    )

    results.data.items.find { |s| s.id.kind == 'youtube#video' }
  rescue Google::APIClient::TransmissionError => e
    e.result.body
  end
end

get '/query' do
  Thread.new {
    puts 'Thread starts'

    video = query_in_youtube params[:text]
    videoId = video.id.videoId
    title = video.snippet.title

    text = "<https://youtu.be/#{videoId}|#{title}>"
    RestClient.post params[:response_url],
      {:response_type => 'in_channel', :text => text}.to_json,
      :content_type => :json
  }

  content_type :json
  {:response_type => 'in_channel', :text => 'Querying...'}.to_json
end
