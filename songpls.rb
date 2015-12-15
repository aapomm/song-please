require 'rubygems'
require 'google/api_client'
require 'rest-client'
require 'sinatra'

DEVELOPER_KEY = ENV['GOOGLE_API_KEY']
YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'

def get_service
  client = Google::APIClient.new(
    :key => DEVELOPER_KEY,
    :authorization => nil,
    :application_name => $PROGRAM_NAME,
    :application_version => '1.0.0'
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
  response_url = params[:response_url]
  video = query_in_youtube params[:text]
  videoId = video.id.videoId
  title = video.snippet.title

  text = "<https://youtu.be/#{videoId}|#{title}>"

  response = RestClient.post response_url, {:text => text}

  status 200
  body ''
end
