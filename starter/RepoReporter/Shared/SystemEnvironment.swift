/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import ComposableArchitecture
import Foundation

@dynamicMemberLookup
struct SystemEnvironment<Environment> {
  var environment: Environment

  subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    set { self.environment[keyPath: keyPath] = newValue }
  }

  var mainQueue: () -> AnySchedulerOf<DispatchQueue>
  var decoder: () -> JSONDecoder

  private static func decoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  static func live(environment: Environment) -> Self {
    Self(environment: environment, mainQueue: { .main }, decoder: decoder)
  }

  static func dev(environment: Environment) -> Self {
    Self(environment: environment, mainQueue: { .main }, decoder: decoder)
  }
}

struct SystemClient {
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var decoder: JSONDecoder
}

extension SystemClient: DependencyKey {
  static var liveValue: SystemClient {
    Self.init(mainQueue: .main,
              decoder: JSONDecoder())
  }
  
  static var testValue: SystemClient {
    Self.init(mainQueue: .main,
              decoder: JSONDecoder())
  }
}

extension DependencyValues {
  var systemClient: SystemClient {
    get {
      self[SystemClient.self]
    }
    set {
      self[SystemClient.self] = newValue
    }
  }
  
  var fetchRepository: FetchRepositoryDependency {
    get {
      self[FetchRepositoryDependency.self]
    }
    set {
      self[FetchRepositoryDependency.self] = newValue
    }
  }
}

struct FetchRepositoryDependency: DependencyKey {
  var fetch: (JSONDecoder) async throws -> [RepositoryModel]
  
  static var liveValue: FetchRepositoryDependency {
    Self.init(fetch: fetchRepository(_:))
  }
  
  static var testValue: FetchRepositoryDependency {
    Self.init { _ in
      let dummyRepositories = [
        RepositoryModel(
          name: "Repo 1",
          description: "This is the first repo. It has a long descriptive text which spans many lines.",
          stars: 5,
          forks: 5,
          language: "Swift"),
        RepositoryModel(
          name: "Repo 2",
          description: "This is another repo.",
          stars: 0,
          forks: 5,
          language: "Python"),
        RepositoryModel(
          name: "Repo 3",
          description: "This is the last repo.",
          stars: 5,
          forks: 0,
          language: "Rust")
      ]
      
      return dummyRepositories
    }
  }
  
  static var previewValue: FetchRepositoryDependency {
    return Self.testValue
  }
  
  
  private static func fetchRepository(_ decoder: JSONDecoder) async throws -> [RepositoryModel] {
    guard let url = URL(string: "https://api.github.com/users/raywenderlich") else {
      throw APIError.downloadError
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let decodedData = try decoder.decode([RepositoryModel].self, from: data)
      
      return decodedData
      
    } catch {
      throw APIError.downloadError
    }
  }
}


