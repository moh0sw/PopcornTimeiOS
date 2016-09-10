

import Foundation
import SwiftyJSON
import Alamofire

class TVAPI {
    private let TVShowsAPIEndpoint = "https://tv-v2.api-fetch.website/"
    /**
     Creates new instance of TVAPI class.
     
     - Returns: Fully initialised TVAPI class.
     */
    static let sharedInstance = TVAPI()
    /**
     Possible genres used in API call.
     */
    enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Animation = "Animation"
        case Comedy = "Comedy"
        case Crime = "Crime"
        case Disaster = "Disaster"
        case Documentary = "Documentary"
        case Drama = "Drama"
        case Family = "Family"
        case FanFilm = "Fan Film"
        case Fantasy = "Fantasy"
        case FilmNoir = "Film Noir"
        case History = "History"
        case Holiday = "Holiday"
        case Horror = "Horror"
        case Indie = "Indie"
        case Music = "Music"
        case Mystery = "Mystery"
        case Road = "Road"
        case Romance = "Romance"
        case SciFi = "Science Fiction"
        case Short = "Short"
        case Sport = "Sports"
        case SportingEvent = "Sporting Event"
        case Suspense = "Suspense"
        case Thriller = "Thriller"
        case War = "War"
        case Western = "Western"
        
        static let arrayValue = [All, Action, Adventure, Animation, Comedy, Crime, Disaster, Documentary, Drama, Family, FanFilm, Fantasy, FilmNoir, History, Holiday, Horror, Indie, Music, Mystery, Road, Romance, SciFi, Short, Sport, SportingEvent, Suspense, Thriller, War, Western]
    }
    /**
     Possible filters used in API call.
     */
    enum filters: String {
        case Popularity = "popularity"
        case Year = "year"
        case Date = "updated"
        case Rating = "rating"
        case Alphabet = "name"
        case Trending = "trending"
        
        static let arrayValue = [Trending, Popularity, Rating, Date, Year, Alphabet]
        
        func stringValue() -> String {
            switch self {
            case .Popularity:
                return "Popular"
            case .Year:
                return "Year"
            case .Date:
                return "Last Updated"
            case .Rating:
                return "Top Rated"
            case .Alphabet:
                return "A-Z"
            case .Trending:
                return "Trending"
            }
        }
    }
    /**
     Possible orders used in API call.
     */
    enum orders: Int {
        case Ascending = 1
        case Descending = -1
        
    }
    /**
     Load TV Shows from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return TV Shows that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     - Parameter order:      Ascending or descending.
     
     - Returns: Array of `PCTShows`.
     */
    func load(
        page: Int,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        order: orders = .Descending,
        completion: (items: [PCTShow]) -> Void) {
        var params: [String: AnyObject] = ["sort": filterBy.rawValue, "genre": genre.rawValue.stringByReplacingOccurrencesOfString(" ", withString: "-").lowercaseString, "order": order.rawValue]
        if let searchTerm = searchTerm where !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        Alamofire.request(.GET, TVShowsAPIEndpoint + "shows/\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let responseDict = JSON(value)
            var shows = [PCTShow]()
            for (_, show) in responseDict {
                guard let id = show["imdb_id"].string,
                    let title = show["title"].string,
                    let year = show["year"].string,
                    let rating = show["rating"]["percentage"].float,
                    let slug = show["slug"].string else { continue }
                var coverImage = show["images"]["poster"].string?.stringByReplacingOccurrencesOfString("original", withString: "thumb")
                let backgroundImage = show["images"]["fanart"].string
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    coverImage = coverImage?.stringByReplacingOccurrencesOfString("thumb", withString: "medium")
                }
                shows.append(PCTShow(id: id, title: title, year: year, coverImageAsString: coverImage, backgroundImageAsString: backgroundImage, rating: rating/20.0, slug: slug))
            }
            completion(items: shows)
        }
    }
    
    /**
     Get detailed TV Show information.
     
     - Parameter imbdId: The imbd identification code.
     
     - Returns: Array of `PCTEpisodes`, the genres of the show, the status of the show (Continuing, Ended etc.), a small description of show and the number of seasons in the show.
     */
    func getShowInfo(imdbId: String, completion: (genres: [String], status: String, synopsis: String, episodes: [PCTEpisode], seasonNumbers: [Int]) -> Void) {
        Alamofire.request(.GET, TVShowsAPIEndpoint + "show/\(imdbId)").validate().responseJSON { response in
            guard let value = response.result.value else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let responseDict = JSON(value)
            let genres = responseDict["genres"].arrayObject as? [String] ?? []
            let status = responseDict["status"].string ?? "Ended"
            let synopsis = responseDict["synopsis"].string ?? "No synopsis available"
            var episodes = [PCTEpisode]()
            var seasons = [Int]()
            for (_, episode) in responseDict["episodes"] {
                guard let seasonNumber = episode["season"].int,
                    let episodeNumber = episode["episode"].int,
                    let tvdbId = episode["tvdb_id"].int,
                    let firstAired = episode["first_aired"].int else { continue }
                if !seasons.contains(seasonNumber) {
                    seasons.append(seasonNumber)
                }
                let title = episode["title"].string ?? "Episode \(episodeNumber)"
                let overview = episode["overview"].string ?? "No synopsis available"
                let airedDate = NSDate(timeIntervalSince1970: Double(firstAired))
                var torrents = [PCTTorrent]()
                for (index, torrent) in episode["torrents"] {
                    if index != "0" {
                        let torrent = PCTTorrent(url: torrent["url"].string, seeds: torrent["seeds"].int ?? 0, peers: torrent["peers"].int ?? 0, quality: index)
                        torrents.append(torrent)
                    }
                }
                torrents.sortInPlace(<)
                episodes.append(PCTEpisode(season: seasonNumber, episode: episodeNumber, title: title, summary: overview, airedDate: airedDate, tvdbId:  String(tvdbId), torrents: torrents))
            }
            seasons.sortInPlace(<)
            episodes.sortInPlace({ $0.episode < $1.episode })
            completion(genres: genres, status: status, synopsis: synopsis, episodes: episodes, seasonNumbers: seasons)
        }
    }
    /**
     Get detailed episode information.
     
     - Parameter episode: The episode you want more information about.
     
     - Returns: ImageURL and subtitles. Completion block called twice. First time when imageURL has been recieved and second when subtitles have been recieved.
     */
    func getEpisodeInfo(episode: PCTEpisode, completion: (imageURLAsString: String?, subtitles: [PCTSubtitle]?) -> Void) {
        TraktTVAPI.sharedInstance.getEpisodeMeta(episode.show!, episode: episode, completion: { (imageURLAsString, imdbId) in
            completion(imageURLAsString: imageURLAsString, subtitles: nil)
            OpenSubtitles.sharedInstance.login({
                OpenSubtitles.sharedInstance.search(episode, imdbId: imdbId, completion: {
                    subtitles in
                    completion(imageURLAsString: imageURLAsString, subtitles: subtitles)
                })
            })
        })
    }
}

func downloadTorrentFile(path: String, completion: (url: String?, error: NSError?) -> Void) {
    if path.hasPrefix("magnet") {
        completion(url: cleanMagnet(path), error: nil)
        return
    }
    var finalPath: NSURL!
    Alamofire.download(.GET, path, destination: { (temporaryURL, response) -> NSURL in
        finalPath = NSURL(fileURLWithPath: downloadsDirectory).URLByAppendingPathComponent(response.suggestedFilename!)
        if NSFileManager.defaultManager().fileExistsAtPath(finalPath.relativePath!) {
            try! NSFileManager.defaultManager().removeItemAtPath(finalPath.relativePath!)
        }
        return finalPath
    }).validate().response { (_, _, _, error) in
        if let error = error {
            print(error)
            completion(url: nil, error: error)
            return
        }
        completion(url: finalPath.relativePath!, error: nil)
    }
}