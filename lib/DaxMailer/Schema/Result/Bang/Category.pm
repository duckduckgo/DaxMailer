package DaxMailer::Schema::Result::Bang::Category;

use Moo;
extends 'DaxMailer::Schema::Result';
use DBIx::Class::Candy;
use Email::Valid;

table 'bang_category';

primary_column id => { data_type => 'int', is_auto_increment => 1 };

column live       => { data_type => 'int', default_value => 1 };
column name       => { data_type => 'text' };
column parent     => { data_type => 'int' };

might_have parent_category => 'DaxMailer::Schema::Result::Bang::Category' => {
    'foreign.id' => 'self.id'
};

belongs_to bang => 'DaxMailer::Schema::Result::Bang' => 'category_id';

1;
