# Manage the feed

Article = ($resource) ->
  return $resource('articles/:id', { id: '' },
    query: { method: 'GET', isArray: true }
    update:
      method: 'PUT'
    )

Article.$inject = ['$resource']



ArticleController = ($scope, Article) ->
  console.log "ARTICLES"

  $scope.articles = []

  $scope.delete = (article) ->
    console.log "DELETE", this.article._id
    Article.delete { id: this.article._id }

  $scope.loadMore = ->
    Article.query({ offset: $scope.articles.length }, (data)->
      $scope.articles = $scope.articles.concat(data)
      $scope.$apply() if not $scope.$$phase
    )

  $scope.loadMore()



ArticleController.$inject = ['$scope', 'Article']



angular.module('rssRunner', ['ngResource'])
  .factory('Article', Article)
  .run()