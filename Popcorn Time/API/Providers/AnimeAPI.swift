

import Foundation
import Alamofire
import SwiftyJSON

class AnimeAPI {
    private let animeAPIEndpoint = "https://api-fetch.website/tv/"
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
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let animes = JSON(response.result.value!)
            var pctAnimes = [PCTShow]()
            for (_, anime) in animes {
                let id = anime["_id"].string!
                let title = anime["title"].string!
                let image = anime["images"]["poster"].string!
                let year = anime["year"].string!
                let rating = anime["rating"]["percentage"].float!/20.0
                let slug = anime["slug"].string!
                let genres = anime["genres"].arrayObject as! [String]
                let show = PCTShow(id: id, title: title, year: year, coverImageAsString: image, rating: rating, slug: slug, genres: genres)
                pctAnimes.append(show)
            }
            completion(items: pctAnimes)
        }
    }
    /**
     Get detailed Anime information.
     
     - Parameter id: The identification code.
     
     Returns: Array of `PCTEpisodes`, the status of the show (Continuing, Ended etc.), a small description of show and the number of seasons in the show.
     */
    func getAnimeInfo(id: String, completion: (status: String, synopsis: String, episodes: [PCTEpisode], seasons: [Int]) -> Void) {
        Alamofire.request(.GET, animeAPIEndpoint + "anime/\(id)").validate().responseJSON { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let show = JSON(response.result.value!)
            let synopsis = show["synopsis"].string!
            let status = show["status"].string!
            var pctEpisodes = [PCTEpisode]()
            var seasons = [Int]()
            for (_, episodes) in show["episodes"] {
                let season = Int(episodes["season"].string!)!
                if !seasons.contains(season) {
                    seasons.append(season)
                }
                let episode = Int(episodes["episode"].string!)!
                let title = episodes["title"].string!
                let overview = episodes["overview"].string ?? "No synopsis available"
                let tvdbId = episodes["tvdb_id"].string!.stringByReplacingOccurrencesOfString("-", withString: "")
                let airedDate = NSDate(timeIntervalSince1970: Double(show["last_updated"].int!))
                var torrents = [PCTTorrent]()
                for (index, torrent) in episodes["torrents"] {
                    if index != "0" {
                        let torrent = PCTTorrent(url: torrent["url"].string ?? "", seeds: torrent["seeds"].int!, peers: torrent["peers"].int!, quality: index)
                        torrents.append(torrent)
                    }
                }
                torrents.sortInPlace(<)
                let pctEpisode = PCTEpisode(season: season, episode: episode, title: title, summary: overview, airedDate: airedDate, tvdbId: tvdbId, torrents: torrents)
                pctEpisodes.append(pctEpisode)
            }
            seasons.sortInPlace(<)
            pctEpisodes.sortInPlace({ $0.episode < $1.episode })
            completion(status: status, synopsis: synopsis, episodes: pctEpisodes, seasons: seasons)
        }
    }
}