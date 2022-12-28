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

import Combine
import ComposableArchitecture
import Foundation


struct RepositoryReducer: ReducerProtocol {
  @Dependency(\.fetchRepository.fetch) @MainActor private var repositoryRequest
  @Dependency(\.systemClient.mainQueue) private var mainQueue
  @Dependency(\.systemClient.decoder) private var decoder
  
  struct State: Equatable {
    var repository = [RepositoryModel]()
    var favoriteRepository = [RepositoryModel]()
  }
  
  enum Action: Equatable {
    case onAppear
    case dataLoded(Result<[RepositoryModel], APIError>)
    case favoriteButtonTaped(RepositoryModel)
  }
  
  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    
    switch action {
    case .onAppear:
      return .task {
        do {
          let result = try await repositoryRequest(decoder)
          return .dataLoded(.success(result))
        } catch {
          return .dataLoded(.failure(.downloadError))
        }
      }
      
    case .dataLoded(let result):
      
      switch result {
      case .success(let repository):
        state.repository = repository
      case .failure:
        break
      }
     
    case .favoriteButtonTaped(let repositoryModel):
      if state.favoriteRepository.contains(repositoryModel) {
        state.favoriteRepository.removeAll { $0 == repositoryModel }
      } else {
        state.favoriteRepository.append(repositoryModel)
      }
    }
    
    return .none
  }
}

