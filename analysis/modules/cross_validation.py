class MyKFoldCV:
    """
    Manages cross validation on participants.

    Attributes:
        dataset_handler: DatasetHandler object
        k: k parameter of cross validation
        ignore: list of participants not to include in the training or validation
        create_test_loaders: boolean flag, if True create the train loader automatically
            for the current train participants
        create_train_loaders: boolean flag, if True creates the train loader automatically
            for the current train participants
        batch_size: batch size parameter to create the train data loaders
    """
    def __init__(self, dataset_handler, k, ignore=None, create_test_loaders=True,
                 create_train_loaders=True, batch_size=1):
        if ignore is None:
            ignore = []
        self.ignore = ignore
        self.dataset_handler = dataset_handler
        self.k = k
        self.batch_size = batch_size
        self.create_train_loaders = create_train_loaders
        self.create_test_loaders = create_test_loaders
        self.participants = [p for p in dataset_handler.get_participants() if p not in ignore]
        self.num_participants = len(self.participants)
        self.test_n = self.num_participants // k
        self.test_id = self.test_n
        self.cur_test = self.participants[:self.test_id]
        self.cur_train = [i for i in self.participants if i not in self.cur_test]
        self.cur_train_loader = None
        self.cur_test_loader = None
        self.init_loaders()

    def init_loaders(self):
        if self.create_train_loaders:
            self.cur_train_loader = self.dataset_handler.get_loader(self.cur_train, self.batch_size, shuffle=True)
        if self.create_test_loaders:
            self.cur_test_loader = self.dataset_handler.get_loader(self.cur_test, self.batch_size, shuffle=False)

    def next_split(self):
        """
        Switches to the next split of participants, updates the cur_test, cur_train and the loaders if the
            respective parameters are True.
        Returns:
            None
        """
        if self.test_id is None:
            self.cur_train_loader = None
            self.cur_test_loader = None
            return
        if self.test_id >= self.num_participants:
            self.test_id = None
            self.cur_test = None
            return
        new_test_id = min(self.test_id + self.test_n, self.num_participants)
        self.cur_test = self.participants[self.test_id:new_test_id]
        self.cur_train = [id for id in self.participants if id not in self.cur_test]
        self.test_id = new_test_id
        self.init_loaders()

    def get_k(self):
        return self.k

    def get_train_loader(self):
        return self.cur_train_loader

    def get_test_loader(self):
        return self.cur_test_loader

    def get_train_ids(self):
        return self.dataset_handler.get_ids(self.cur_train)

    def get_test_ids(self):
        return self.dataset_handler.get_ids(self.cur_test)

    def get_train_participants(self):
        return self.cur_train

    def get_test_participants(self):
        return self.cur_test

    def get_participants(self):
        return self.participants
