import Combine
import Foundation
import Models
import SwiftGraphQL

public extension DataService {
  func articlePublisher(slug: String) -> AnyPublisher<FeedItem, BasicError> {
    internalViewerPublisher()
      .flatMap { self.internalArticlePublisher(username: $0.username, slug: slug) }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}

extension DataService {
  func internalArticlePublisher(username: String, slug: String) -> AnyPublisher<FeedItem, BasicError> {
    enum QueryResult {
      case success(result: FeedItem)
      case error(error: String)
    }

    let selection = Selection<QueryResult, Unions.ArticleResult> {
      try $0.on(
        articleSuccess: .init { QueryResult.success(result: try $0.article(selection: homeFeedItemSelection)) },
        articleError: .init { QueryResult.error(error: try $0.errorCodes().description) }
      )
    }

    let query = Selection.Query {
      try $0.article(username: username, slug: slug, selection: selection)
    }

    let path = appEnvironment.graphqlPath
    let headers = networker.defaultHeaders

    return Deferred {
      Future { promise in
        send(query, to: path, headers: headers) { result in
          switch result {
          case let .success(payload):
            switch payload.data {
            case let .success(result: result):
              promise(.success(result))
            case let .error(error: error):
              promise(.failure(.message(messageText: error.debugDescription)))
            }
          case .failure:
            promise(.failure(.message(messageText: "ger article fetch failed")))
          }
        }
      }
    }
    .eraseToAnyPublisher()
  }
}

public extension DataService {
  func libraryItemsPublisher(
    limit: Int,
    sortDescending: Bool,
    searchQuery: String?,
    cursor: String?
  ) -> AnyPublisher<HomeFeedData, ServerError> {
    enum QueryResult {
      case success(result: HomeFeedData)
      case error(error: String)
    }

    let selection = Selection<QueryResult, Unions.ArticlesResult> {
      try $0.on(
        articlesSuccess: .init {
          QueryResult.success(
            result: HomeFeedData(
              items: try $0.edges(selection: articleEdgeSelection.list)
            )
          )
        },
        articlesError: .init {
          QueryResult.error(error: try $0.errorCodes().description)
        }
      )
    }

    let query = Selection.Query {
      try $0.articles(
        sharedOnly: .present(false),
        sort: OptionalArgument(
          InputObjects.SortParams(
            order: .present(sortDescending ? .descending : .ascending),
            by: .updatedTime
          )
        ),
        after: OptionalArgument(cursor),
        first: OptionalArgument(limit),
        query: OptionalArgument(searchQuery),
        selection: selection
      )
    }

    let path = appEnvironment.graphqlPath
    let headers = networker.defaultHeaders

    return Deferred {
      Future { promise in
        send(query, to: path, headers: headers) { result in
          switch result {
          case let .success(payload):
            switch payload.data {
            case let .success(result: result):
              // TODO: check local db to see what has a local documentpath
              promise(.success(result))
            case .error:
              promise(.failure(.unknown))
            }
          case .failure:
            promise(.failure(.unknown))
          }
        }
      }
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
  }
}

let highlightSelection = Selection.Highlight {
  Highlight(
    id: try $0.id(),
    shortId: try $0.shortId(),
    quote: try $0.quote(),
    prefix: try $0.prefix(),
    suffix: try $0.suffix(),
    patch: try $0.patch(),
    annotation: try $0.annotation()
  )
}

let homeFeedItemSelection = Selection.Article {
  FeedItem(
    id: try $0.id(),
    title: try $0.title(),
    readingProgress: try $0.readingProgressPercent(),
    readingProgressAnchor: try $0.readingProgressAnchorIndex(),
    imageURLString: try $0.image(),
    onDeviceImageURLString: nil,
    documentDirectoryPath: nil,
    pageURLString: try $0.url(),
    description: try $0.description(),
    publisherURLString: try $0.originalArticleUrl(),
    author: try $0.author(),
    publishDate: try $0.publishedAt()?.value,
    slug: try $0.slug(),
    isArchived: try $0.isArchived(),
    contentReader: try $0.contentReader().rawValue,
    highlights: try $0.highlights(selection: highlightSelection.list)
  )
}

private let articleEdgeSelection = Selection.ArticleEdge {
  try $0.node(selection: homeFeedItemSelection)
}
