

import Foundation
import Alamofire
import SwiftyJSON

class AnimeAPI {
    private let animeAPIEndpoint = "https://tv-v2.api-fetch.website/"
    /**
     Creates new instance of AnimeAPI class
     
     - Returns: Fully initialised AnimeAPI class
     */
    static let sharedInstance = AnimeAPI()
    /**
     Possible genres used in API call.
     */
    enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Comedy = "Comedy"
        case Dementia = "Dementia"
        case Demons = "Demons"
        case Drama = "Drama"
        case Ecchi = "Ecchi"
        case Fantasy = "Fantasy"
        case Game = "Game"
        case GenderBender = "Gender Bender"
        case Gore = "Gore"
        case Harem = "Harem"
        case Historical = "Historical"
        case Horror = "Horror"
        case Kids = "Kids"
        case Magic = "Magic"
        case MahouShoujo = "Mahou Shoujo"
        case MahouShounen = "Mahou Shounen"
        case MartialArts = "Martial Arts"
        case Mecha = "Mecha"
        case Military = "Military"
        case Music = "Music"
        case Mystery = "Mystery"
        case Parody = "Parody"
        case Police = "Police"
        case Psychological = "Psychological"
        case Racing = "Racing"
        case Romance = "Romance"
        case Samurai = "Samurai"
        case School = "School"
        case SciFi = "Sci-Fi"
        case ShounenAi = "Shounen Ai"
        case ShoujoAi = "Shoujo Ai"
        case SliceOfLife = "Slice of Life"
        case Space = "Space"
        case Sports = "Sports"
        case Supernatural = "Supernatural"
        case SuperPower = "Super Power"
        case Thriller = "Thriller"
        case Vampire = "Vampire"
        case Yuri = "Yuri"
        
        static let arrayValue = [All, Action, Adventure, Comedy, Dementia, Demons, Drama, Ecchi, Fantasy, Game, GenderBender, Gore, Harem, Historical, Horror, Kids, Magic, MahouShoujo, MahouShounen, MartialArts, Mecha, Military, Music, Mystery, Parody, Police, Psychological, Racing, Romance, Samurai, School, SciFi, ShounenAi, ShoujoAi, SliceOfLife, Space, Sports, Supernatural, SuperPower, Thriller, Vampire, Yuri]
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
        
        static let arrayValue = [Popularity, Rating, Date, Year, Alphabet]
        
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
     Load Anime from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return anime that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     - Parameter order:      Ascending or descending.
     
     - Returns: Array of `PCTAnimes`.
     */
    func load(
        page: Int,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        order: orders = .Descending,
        completion: (items: [PCTShow]) -> Void) {
        var params: [String: AnyObject] = ["sort": filterBy.rawValue, "type": genre.rawValue, "order": order.rawValue]
        if searchTerm != nil {
            params["keywords"] = searchTerm!
        }
        Alamofire.request(.GET, animeAPIEndpoint + "animes/\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let responseDict = JSON(value)
            var animes = [PCTShow]()
            for (_, anime) in responseDict {
                guard let id = anime["_id"].string,
                    let title = anime["title"].string,
                    let image = anime["images"]["poster"].string,
                    let backgroundImage = anime["images"]["fanart"].string?.stringByReplacingOccurrencesOfString("large", withString: "original"),
                    let year = anime["year"].string,
                    let rating = anime["rating"]["percentage"].float,
                    let slug = anime["slug"].string,
                    let genres = anime["genres"].arrayObject as? [String]
                else { continue }
                animes.append(PCTShow(id: id, title: title, year: year, coverImageAsString: image, backgroundImageAsString: backgroundImage, rating: rating/20.0, slug: slug, genres: genres))
            }
            completion(items: animes)
        }
    }
    /**
     Get detailed Anime information.
     
     - Parameter id: The identification code.
     
     Returns: Array of `PCTEpisodes`, the status of the show (Continuing, Ended etc.), a small description of show and the number of seasons in the show.
     */
    func getAnimeInfo(id: String, completion: (status: String, synopsis: String, episodes: [PCTEpisode], seasons: [Int]) -> Void) {
        Alamofire.request(.GET, animeAPIEndpoint + "anime/\(id)").validate().responseJSON { response in
            guard let value = response.result.value else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let responseDict = JSON(value)
            let synopsis = responseDict["synopsis"].string ?? "No synopsis available."
            let status = responseDict["status"].string ?? "Ended"
            var episodes = [PCTEpisode]()
            var seasons = [Int]()
            for (_, episode) in responseDict["episodes"] {
                guard let seasonString = episode["season"].string,
                    let episodeString = episode["episode"].string,
                    let title = episode["title"].string,
                    let tvdbId = episode["tvdb_id"].string?.stringByReplacingOccurrencesOfString("-", withString: ""),
                    let lastUpdated = responseDict["last_updated"].int
                else { continue }
                let seasonNumber = Int(seasonString)!
                if !seasons.contains(seasonNumber) {
                    seasons.append(seasonNumber)
                }
                let episodeNumber = Int(episodeString)!
                let overview = episode["overview"].string ?? "No synopsis available."
                let airedDate = NSDate(timeIntervalSince1970: Double(lastUpdated))
                var torrents = [PCTTorrent]()
                for (index, torrent) in episode["torrents"] {
                    if index != "0" {
                        let torrent = PCTTorrent(url: torrent["url"].string, seeds: torrent["seeds"].int ?? 0, peers: torrent["peers"].int ?? 0, quality: index)
                        torrents.append(torrent)
                    }
                }
                torrents.sortInPlace(<)
                episodes.append(PCTEpisode(season: seasonNumber, episode: episodeNumber, title: title, summary: overview, airedDate: airedDate, tvdbId: tvdbId, torrents: torrents))
            }
            seasons.sortInPlace(<)
            episodes.sortInPlace({ $0.episode < $1.episode })
            completion(status: status, synopsis: synopsis, episodes: episodes, seasons: seasons)
        }
    }
}