

import Foundation
import SwiftyJSON
import Alamofire

class MovieAPI {
    private let moviesAPIEndpoint = "https://api-fetch.website/tv/movies/"
    /**
     Creates new instance of MovieAPI class.
     
     - Returns: Fully initialised MovieAPI class.
     */
    static let sharedInstance = MovieAPI()
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
        case Trending = "trending"
        case Popularity = "seeds"
        case Rating = "rating"
        case Date = "last added"
        case Year = "year"
        case Alphabet = "title"
        
        static let arrayValue = [Trending, Popularity, Rating, Date, Year, Alphabet]
        
        func stringValue() -> String {
            switch self {
            case .Popularity:
                return "Popular"
            case .Year:
                return "Year"
            case .Date:
                return "Release Date"
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
     Load Movies from API.
     
     - Parameter page:       The page number to load.
     - Parameter limit:      The number of movies to be recieved.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return movies that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     - Parameter order:      Ascending or descending.
     
     - Returns: Array of `PCTMovies`.
     */
    func load(
        page: Int,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        order: orders = .Descending,
        completion: (items: [PCTMovie]) -> Void) {
        var params: [String: AnyObject] = ["sort": filterBy.rawValue, "order": order.rawValue, "genre": genre.rawValue.stringByReplacingOccurrencesOfString(" ", withString: "-").lowercaseString]
        if let searchTerm = searchTerm where !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        Alamofire.request(.GET, moviesAPIEndpoint + "\(page)", parameters: params).validate().responseJSON { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let movies =  JSON(response.result.value!)
            var pctMovies = [PCTMovie]()
            for (_, movie) in movies {
                let description = movie["synopsis"].string!
                let runtime = movie["runtime"].string!
                let trailorString = movie["trailer"].string!.sliceFrom("=", to: "")
                let rating = movie["rating"]["percentage"].float!/20.0
                let title = movie["title"].string!
                let year = movie["year"].string!
                let coverImage = movie["images"]["poster"].string!.stringByReplacingOccurrencesOfString("original", withString: "thumb")
                let id = movie["imdb_id"].string!
                let genres = movie["genres"].arrayObject! as! [String]
                var torrents = [PCTTorrent]()
                for (quality, torrent) in movie["torrents"]["en"] {
                    torrents.append(PCTTorrent(url: torrent["url"].string!, seeds: torrent["seed"].int!, peers: torrent["peer"].int!, quality: quality, size: torrent["filesize"].string!))
                }
                torrents.sortInPlace(<)
                let pctMovie = PCTMovie(title: title, year: year, coverImageAsString: coverImage, imdbId: id, rating: rating, torrents: torrents, genres: genres, summary: description, runtime: runtime, trailorURLString: trailorString)
                pctMovies.append(pctMovie)
            }
            completion(items: pctMovies)
        }
    }
}