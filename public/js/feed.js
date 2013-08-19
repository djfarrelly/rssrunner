var Article, ArticleController;

Article = function($resource) {
  return $resource('articles/:id', {
    id: ''
  }, {
    query: {
      method: 'GET',
      isArray: true
    },
    update: {
      method: 'PUT'
    }
  });
};

Article.$inject = ['$resource'];

ArticleController = function($scope, Article) {
  console.log("ARTICLES");
  $scope.articles = [];
  $scope["delete"] = function(article) {
    console.log("DELETE", this.article._id);
    this.article.archived = true;
    return Article["delete"]({
      id: this.article._id
    });
  };
  $scope.loadMore = function() {
    return Article.query({
      offset: $scope.articles.length
    }, function(data) {
      $scope.articles = $scope.articles.concat(data);
      if (!$scope.$$phase) {
        return $scope.$apply();
      }
    });
  };
  return $scope.loadMore();
};

ArticleController.$inject = ['$scope', 'Article'];

angular.module('rssRunner', ['ngResource']).factory('Article', Article).run();
